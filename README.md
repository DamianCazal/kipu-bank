# KipuBank

## Descripción

KipuBank es un contrato inteligente desarrollado en Solidity que simula el funcionamiento básico de un banco descentralizado.  
Permite a los usuarios depositar ETH en bóvedas personales y realizar retiros hasta un límite máximo por transacción.  
Además, el contrato impone un límite global de depósitos totales que puede almacenar.

El contrato fue diseñado siguiendo buenas prácticas de seguridad, manejo de errores y documentación NatSpec.

---

## Funcionalidades principales

1. **Depositar ETH**  
   Los usuarios pueden depositar ETH mediante la función `deposit()`.  
   Cada depósito actualiza el balance individual del usuario y el total del banco.  
   Se emite el evento `SuccessfulDeposit`.

2. **Retirar ETH**  
   Los usuarios pueden retirar fondos con `withdraw(uint256 _amount)`.  
   No se puede retirar más del límite establecido por transacción (`i_maxWithdrawal`).  
   Tampoco se puede retirar más del saldo disponible.  
   Se emite el evento `SuccessfulWithdrawal`.

3. **Consultas**  
   - `getBalance(address user)`: devuelve el balance interno del usuario.  
   - `getBankStats()`: devuelve el estado general del banco (total de depósitos, retiros, límites y balance total).

4. **Recepción directa de ETH**  
   El contrato implementa las funciones `receive()` y `fallback()` para aceptar depósitos directos de ETH sin necesidad de llamar explícitamente a `deposit()`.

---

## Parámetros del constructor

| Parámetro | Tipo | Descripción |
|------------|------|-------------|
| `_bankCap` | uint256 | Límite total que el contrato puede almacenar (en wei). |
| `_maxWithdrawal` | uint256 | Monto máximo que se puede retirar por transacción (en wei). |

Ejemplo de despliegue:

_bankCap = 10000000000000000000 // 10 ETH en wei

_maxWithdrawal = 2000000000000000000 // 2 ETH en wei


---

## Ejemplo de uso en Remix

1. Compilar el contrato con Solidity 0.8.0 o superior.  
2. Desplegar con los valores de constructor en wei.  
3. Para depositar:

Depositar esta cantidad 1000000000000000000 que representa 1 ETH esto lo ponemos en la funcion deposit()

4. Para retirar:

Poniendo este valor 500000000000000000  en la funcion withdraw() para retirar medio ETH es decir 0.5 ETH por ejemplo

5. Consultar balance:
Usamos la funcion getBalance(msg.sender) donde msg.sender representa la direccion de nuestra billetera.


