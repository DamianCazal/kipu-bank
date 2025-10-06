// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;

/**
 * @title KipuBank
 * @author Damian Cazal
 * @notice Banco simple donde usuarios depositan ETH en bóvedas personales y retiran hasta un límite por transacción.
 */
contract KipuBank {

    /// @notice Límite máximo que un usuario puede retirar por transacción.
    uint256 public immutable i_maxWithdrawal;

    /// @notice Límite global de depósitos que el banco puede almacenar.
    uint256 public immutable i_bankCap;

    /// @notice Mapping de balances por usuario.
    mapping(address => uint256) private s_balances;

    /// @notice Conteo total de depósitos realizados.
    uint256 public s_totalDepositsCount;

    /// @notice Conteo total de retiros realizados.
    uint256 public s_totalWithdrawalsCount;

    /// @notice Balance total actualmente custodiado por el contrato.
    uint256 public s_totalBalance;

    /// @notice Emitido cuando un usuario deposita ETH correctamente.
    /// @param user Dirección del depositante.
    /// @param amount Cantidad depositada.
    event SuccessfulDeposit(address indexed user, uint256 amount);

    /// @notice Emitido cuando un usuario retira ETH correctamente.
    /// @param user Dirección que originó el retiro.
    /// @param to Dirección destino que recibe los fondos.
    /// @param amount Cantidad retirada.
    event SuccessfulWithdrawal(address indexed user, address indexed to, uint256 amount);

    /// @notice Se emite cuando el constructor recibe valores inválidos.
    /// @param bankCap Valor de bankCap pasado.
    /// @param maxWithdrawal Valor de maxWithdrawal pasado.
    error InvalidConstructorParams(uint256 bankCap, uint256 maxWithdrawal);

    /// @notice Se emite cuando se intenta depositar 0.
    error ZeroDeposit();

    /// @notice Se emite cuando el depósito excede la capacidad restante del banco.
    /// @param attempted Monto que se intentó depositar.
    /// @param available Capacidad disponible restante.
    error DepositExceedsCap(uint256 attempted, uint256 available);

    /// @notice Se emite cuando el monto de retiro excede el límite por transacción.
    /// @param attempted Monto solicitado.
    /// @param limit Límite permitido por transacción.
    error WithdrawalExceedsLimit(uint256 attempted, uint256 limit);

    /// @notice Se emite cuando el usuario no tiene suficiente balance.
    /// @param user Dirección del usuario.
    /// @param balance Balance disponible.
    /// @param attempted Monto solicitado.
    error InsufficientBalance(address user, uint256 balance, uint256 attempted);

    /// @notice Se emite cuando la transferencia `call` falla.
    /// @param to Dirección receptora.
    /// @param amount Monto que se intentó enviar.
    error TransferFailed(address to, uint256 amount);

    /// @notice Valida que la cantidad no sea cero.
    modifier nonZeroAmount(uint256 _amount) {
        if (_amount == 0) revert ZeroDeposit();
        _;
    }

    /**
     * @notice Inicializa el contrato con un bankCap (cap global de depósitos) y un máximo de retiro por tx.
     * @param _bankCap Límite global de fondos que el contrato puede retener (wei).
     * @param _maxWithdrawal Límite por transacción que cualquier usuario puede retirar (wei).
     */
    constructor(uint256 _bankCap, uint256 _maxWithdrawal) {
        if (_bankCap == 0 || _maxWithdrawal == 0) {
            revert InvalidConstructorParams(_bankCap, _maxWithdrawal);
        }
        i_bankCap = _bankCap;
        i_maxWithdrawal = _maxWithdrawal;
    }

    /**
     * @notice Deposita ETH en la bóveda del remitente.
     */
    function deposit() public payable {
        if (msg.value == 0) revert ZeroDeposit();

        uint256 newTotal = s_totalBalance + msg.value;
        if (newTotal > i_bankCap) {
            uint256 available = i_bankCap - s_totalBalance;
            revert DepositExceedsCap(msg.value, available);
        }

        s_balances[msg.sender] += msg.value;
        s_totalDepositsCount += 1;
        s_totalBalance = newTotal;

        // No hay transferencias salientes en deposit; emitimos evento
        emit SuccessfulDeposit(msg.sender, msg.value);
    }

    /*
     * @notice Retira `amount` de la bóveda del remitente y se lo envía a `msg.sender`.
     * @param _amount Cantidad a retirar (wei).
     */
    function withdraw(uint256 _amount) external nonZeroAmount(_amount) {
        if (_amount > i_maxWithdrawal) {
            revert WithdrawalExceedsLimit(_amount, i_maxWithdrawal);
        }

        uint256 userBalance = s_balances[msg.sender];
        if (userBalance < _amount) {
            revert InsufficientBalance(msg.sender, userBalance, _amount);
        }

        s_balances[msg.sender] = userBalance - _amount;
        s_totalWithdrawalsCount += 1;
        s_totalBalance -= _amount;

        _executeWithdrawal(msg.sender, _amount);

        emit SuccessfulWithdrawal(msg.sender, msg.sender, _amount);
    }

    /*
     * @notice Ejecuta la transferencia de ETH hacia `to`.
     * @param to Dirección destino.
     * @param amount Monto a enviar (wei).
     */
    function _executeWithdrawal(address to, uint256 amount) private {
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) revert TransferFailed(to, amount);
    }

    /*
     * @notice Obtiene el balance interno guardado para una dirección.
     * @param user Dirección del usuario.
     * @return balance Balance en wei.
     */
    function getBalance(address user) external view returns (uint256 balance) {
        return s_balances[user];
    }

    /*
     * @notice Devuelve información resumida del banco.
     * @return totalBalance Balance total custodiado por el contrato.
     * @return depositsCount Cantidad de depósitos.
     * @return withdrawalsCount Cantidad de retiros.
     * @return bankCap Límite global de depósitos.
     * @return maxWithdrawal Límite de retiro por transacción.
     */
    function getBankStats() external view returns (uint256 totalBalance, uint256 depositsCount, uint256 withdrawalsCount, uint256 bankCap, uint256 maxWithdrawal) {
        return (s_totalBalance, s_totalDepositsCount, s_totalWithdrawalsCount, i_bankCap, i_maxWithdrawal);
    }

    /// @notice Permite recibir ETH directamente y lo trata como deposit().
    receive() external payable {
        deposit();
    }

    fallback() external payable {
        // si llegan datos, igual intentamos depositar (o podrías revertir)
        if (msg.value > 0) {
            deposit();
        }
    }
}
