# CryptoCampo

Proyecto académico de contratos inteligentes desarrollado con Solidity y Foundry. CryptoCampo combina un token ERC-20 de prueba (BUSD) con un mercado de NFTs ERC-721 (CCNFT), cuyo valor se expresa y liquida utilizando BUSD.

> **Red de demostración:** Ethereum Sepolia. BUSD aquí es un token de prueba creado para este proyecto; no es el BUSD oficial ni representa dinero real. Los contratos no deben utilizarse con fondos reales sin una revisión de seguridad independiente.

## 1. Funcionalidades

### BUSD

Token ERC-20 utilizado como medio de pago dentro de CryptoCampo.

### CCNFT

Contrato ERC-721 enumerable que implementa tres flujos principales:

- **Compra (`buy`)**: permite comprar uno o varios NFTs de un valor previamente autorizado. El contrato emite los NFTs, actualiza `totalValue`, transfiere el importe de compra a `fundsCollector` y cobra `buyFee` a `feesCollector`.
- **Mercado interno (`putOnSale` y `trade`)**: el propietario publica un NFT con un precio en BUSD. Otro usuario puede comprarlo; el vendedor recibe el precio y el contrato cobra `tradeFee`. Después se transfiere el NFT y se retira de la lista de venta.
- **Reclamo (`claim`)**: el propietario presenta una lista de IDs. El contrato quema esos NFTs, reduce `totalValue` y solicita a `fundsCollector` el importe original más el porcentaje `profitToPay`.

Las comisiones y el beneficio utilizan una escala de puntos básicos: 10.000 equivale al 100 %. Por ejemplo, `buyFee = 250` representa 2,5 % y `profitToPay = 500` representa 5 %.

Las transferencias ERC-721 públicas estándar están bloqueadas en CCNFT; el intercambio se realiza mediante el mercado interno (`trade`).

## 2. Tecnologías y configuración

- Solidity: `0.8.19` (los contratos declaran `pragma ^0.8.19`).
- Foundry: Forge, Cast y scripts Solidity.
- OpenZeppelin Contracts: `4.5.0`.
- `forge-std` para pruebas y scripts.
- Red de despliegue y demostración: Sepolia (Chain ID `11155111`).

La configuración registrada en `foundry.toml` es:

```toml
[profile.default]
src = "src"
test = "test"
script = "script"
out = "out"
libs = ["lib"]

solc_version = "0.8.19"
optimizer = true
optimizer_runs = 200
```

## 3. Estructura del proyecto

```text
CryptoCampo/
├── src/
│   ├── BUSD.sol
│   └── CCNFT.sol
├── test/
│   ├── BUSD.t.sol
│   └── CCNFT.t.sol
├── script/
│   ├── Deploy.s.sol
│   ├── DeployBUSD.s.sol
│   └── DeployCCNFT.s.sol
├── lib/
│   ├── forge-std/
│   └── openzeppelin-contracts/
├── foundry.toml
├── .env.example
├── .gitignore
└── README.md
```

## 4. Requisitos

- Git.
- Foundry instalado.
- Una cuenta de prueba de Ethereum con ETH de Sepolia para pagar gas.
- Un endpoint RPC de Sepolia.
- Una API Key de Etherscan si se desea verificar el código fuente.

Instalación de Foundry: <https://book.getfoundry.sh/getting-started/installation>.

Si las dependencias no están presentes en `lib/`, instalarlas desde la raíz del proyecto:

```bash
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts@v4.5.0
```

## 5. Configuración local

Crear el archivo `.env` a partir de `.env.example` y completar los valores localmente:

```bash
cp .env.example .env
nano .env
```

Variables requeridas:

```dotenv
SEPOLIA_RPC_URL="URL_RPC_DE_SEPOLIA"
PRIVATE_KEY="0xCLAVE_PRIVADA_DE_LA_CUENTA_DE_PRUEBA"
ETHERSCAN_API_KEY="API_KEY_DE_ETHERSCAN"
```

Cargar las variables en la terminal antes de ejecutar scripts:

```bash
set -a
source .env
set +a
```

**Seguridad:** nunca subir `.env`, claves privadas ni frases semilla al repositorio, compartirlas por chat o incluirlas en capturas. Usar una cuenta dedicada a pruebas y mantener `.env` excluido mediante `.gitignore`.

## 6. Compilar y ejecutar pruebas

Desde la raíz del proyecto:

```bash
forge build
forge test
```

Resultado registrado durante el desarrollo del proyecto: **21 pruebas aprobadas, 0 fallidas** (5 pruebas de BUSD y 16 de CCNFT, incluyendo los flujos `buy`, `claim` y `trade`). Volver a ejecutar `forge test` para reproducir el resultado en el entorno local.

Comandos adicionales útiles:

```bash
forge fmt
forge snapshot
```

## 7. Scripts de despliegue

Hay tres scripts disponibles:

- `Deploy.s.sol:Deploy`: despliega BUSD y CCNFT juntos y configura CCNFT.
- `DeployBUSD.s.sol:DeployBUSD`: despliega solamente BUSD.
- `DeployCCNFT.s.sol:DeployCCNFT`: despliega CCNFT utilizando una dirección BUSD existente, configura los parámetros y autoriza a CCNFT a retirar BUSD desde el deployer para los reclamos.

### Despliegue conjunto (red nueva o entorno nuevo)

Simulación, sin enviar transacciones:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url "$SEPOLIA_RPC_URL"
```

Despliegue real (solo cuando se desea crear un conjunto nuevo de contratos):

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url "$SEPOLIA_RPC_URL" --broadcast --slow
```

### Despliegue independiente

Primero, desplegar BUSD:

```bash
forge script script/DeployBUSD.s.sol:DeployBUSD --rpc-url "$SEPOLIA_RPC_URL" --broadcast --slow
```

Guardar la dirección resultante y utilizarla para desplegar CCNFT:

```bash
export BUSD_ADDRESS="DIRECCION_DEL_BUSD_DESPLEGADO"
forge script script/DeployCCNFT.s.sol:DeployCCNFT --rpc-url "$SEPOLIA_RPC_URL"
```

Después de revisar la simulación, transmitir el despliegue:

```bash
forge script script/DeployCCNFT.s.sol:DeployCCNFT --rpc-url "$SEPOLIA_RPC_URL" --broadcast --slow --gas-estimate-multiplier 900
```

En el despliegue de demostración de este repositorio, el multiplicador 900 fue el utilizado con éxito para CCNFT en Sepolia. **No es un valor universal ni debe copiarse sin revisar la simulación y las reglas vigentes de la red.** Los límites de gas y las reglas de ejecución pueden cambiar entre redes y actualizaciones. No repetir un comando de despliegue si ya se transmitió correctamente: registrar primero las direcciones y hashes existentes.

> Los comandos de despliegue crean contratos nuevos. No ejecutarlos sobre la red donde ya existe la instancia del proyecto, salvo que deliberadamente se quiera crear otra instancia.

## 8. Despliegue definitivo en Sepolia

Chain ID: `11155111`.

| Contrato | Dirección | Etherscan |
|---|---|---|
| BUSD | `0x6509C8BBdbBBeEe756C6Cd66c2DA2a3e471224cd` | [Contrato BUSD](https://sepolia.etherscan.io/address/0x6509c8bbdbbbeee756c6cd66c2da2a3e471224cd) |
| CCNFT | `0x772D607A67f783F2b0E0584ccF3dBEa0d67a28B4` | [Contrato CCNFT](https://sepolia.etherscan.io/address/0x772d607a67f783f2b0e0584ccf3dbea0d67a28b4) |

Ambos contratos quedaron verificados en Etherscan.

### Configuración comprobada en CCNFT

| Parámetro | Valor confirmado |
|---|---:|
| `fundsToken` | Dirección del BUSD de la tabla anterior |
| `fundsCollector` | `0x8d39B0d5d2D290Aebf59243FAe5f7d6507570EA0` |
| `feesCollector` | `0x8d39B0d5d2D290Aebf59243FAe5f7d6507570EA0` |
| `buyFee` | `250` (2,5 %) |
| `tradeFee` | `300` (3 %) |
| `profitToPay` | `500` (5 %) |
| `maxBatchCount` | `5` |
| `maxValueToRaise` | `1.000.000 BUSD` (18 decimales) |
| Valores habilitados | `100`, `500` y `1.000 BUSD` |
| `canBuy` | `true` |
| `canClaim` | `true` |
| `canTrade` | `true` |

En el despliegue de demostración, `fundsCollector` y `feesCollector` son la cuenta deployer. El script `DeployCCNFT.s.sol` también otorgó a CCNFT una autorización BUSD máxima desde el deployer, necesaria para financiar los reclamos. Esta configuración es para pruebas; debe revisarse antes de cualquier uso productivo.

## 9. Verificación de contratos en Etherscan

Cargar las variables del `.env` y verificar cada contrato:

```bash
forge verify-contract --chain sepolia --etherscan-api-key "$ETHERSCAN_API_KEY" 0x6509C8BBdbBBeEe756C6Cd66c2DA2a3e471224cd src/BUSD.sol:BUSD

forge verify-contract --chain sepolia --etherscan-api-key "$ETHERSCAN_API_KEY" 0x772D607A67f783F2b0E0584ccF3dBEa0d67a28B4 src/CCNFT.sol:CCNFT
```

Si Etherscan devuelve `Pending in queue`, consultar el GUID que devuelve Foundry (no volver a enviar la solicitud):

```bash
forge verify-check --chain sepolia --retries 20 --delay 10 GUID_DEVUELTO
```

Estado de este proyecto: BUSD y CCNFT verificados correctamente.

## 10. Operaciones demostradas en Sepolia

El flujo se probó con tres cuentas: deployer, comprador primario y comprador secundario. Las claves privadas no forman parte de esta documentación.

| Operación | Transacción | Resultado |
|---|---|---|
| Creación BUSD | [`0x59ddbf68e54fd6272cac8c8f6d1ca146b7337d68bfa14445655f396ce03e320d`](https://sepolia.etherscan.io/tx/0x59ddbf68e54fd6272cac8c8f6d1ca146b7337d68bfa14445655f396ce03e320d) | Confirmada |
| Creación CCNFT | [`0xea6c44a038ed8bedf0b0fb739a0d42cd850e7295c8c2d729748cffbdb19ac0cb`](https://sepolia.etherscan.io/tx/0xea6c44a038ed8bedf0b0fb739a0d42cd850e7295c8c2d729748cffbdb19ac0cb) | Confirmada |
| Publicación NFT #1 | [`0x168ae08f03731e056a4090dca272b4ec517267c6186e6b70cdc77d6a6b832bc7`](https://sepolia.etherscan.io/tx/0x168ae08f03731e056a4090dca272b4ec517267c6186e6b70cdc77d6a6b832bc7) | Confirmada; precio 120 BUSD |
| Trade NFT #1 | [`0x4c145a3e6036cc329d14b30c8bbb75257218f6fc57a141d9d0ca238362b8ce4a`](https://sepolia.etherscan.io/tx/0x4c145a3e6036cc329d14b30c8bbb75257218f6fc57a141d9d0ca238362b8ce4a) | Confirmada; comisión 3,6 BUSD |
| Claim NFT #1 | [`0xa7223e827be87e97dcdca05ee9e570554953abe54cc2990b77ce3eb1a7a240f3`](https://sepolia.etherscan.io/tx/0xa7223e827be87e97dcdca05ee9e570554953abe54cc2990b77ce3eb1a7a240f3) | Confirmada; pago 105 BUSD y NFT quemado |

**Pendiente de completar para la entrega:** agregar el hash de la transacción de compra inicial (`buy`) cuando se recupere del historial de la cuenta o de Etherscan. La compra inicial y el flujo posterior fueron comprobados mediante el propietario, los balances y el reclamo, pero el hash de esa compra no está incluido en el registro de esta documentación.

### Resultado de la demostración funcional

- La compra inicial emitió el NFT #1 por 100 BUSD, con una comisión de compra del 2,5 % (2,5 BUSD).
- El vendedor publicó el NFT #1 por 120 BUSD.
- El comprador secundario pagó 120 BUSD al vendedor y 3,6 BUSD de comisión (3 %).
- El comprador secundario reclamó el NFT y recibió 100 BUSD de capital más 5 BUSD de beneficio (5 %).
- Después del reclamo, `balanceOf(compradorsecundario) = 0`, `totalSupply() = 0`, `totalValue() = 0` y `values(1) = 0`. La consulta `ownerOf(1)` revirtió porque el token ya no existe.

## 11. Interacción manual mediante Etherscan y MetaMask

Con los contratos verificados se pueden utilizar las pestañas **Read Contract** y **Write Contract** en Sepolia Etherscan.

- BUSD: <https://sepolia.etherscan.io/address/0x6509c8bbdbbbeee756c6cd66c2da2a3e471224cd#writeContract>
- CCNFT: <https://sepolia.etherscan.io/address/0x772d607a67f783f2b0e0584ccf3dbea0d67a28b4#writeContract>

Para comprar o comerciar, el usuario debe disponer de BUSD y ETH de Sepolia para gas, y otorgar a CCNFT el allowance necesario mediante `approve`. Para `claim`, `fundsCollector` debe disponer de BUSD y haber autorizado al contrato CCNFT a transferirlo.

## 12. Limitaciones y consideraciones de seguridad

- Proyecto académico desplegado en Sepolia; los tokens de prueba no tienen valor monetario.
- No constituye una auditoría de seguridad. Se recomienda una auditoría independiente antes de cualquier despliegue productivo.
- Los setters protegidos por `onlyOwner` concentran facultades administrativas en el propietario.
- En la configuración demostrada, el deployer controla tanto la recepción de fondos como la recepción de comisiones.
- El script otorga una aprobación BUSD máxima a CCNFT desde `fundsCollector`; para producción debe evaluarse cuidadosamente la política de allowances y custodia.
- Deben revisarse límites, comisiones, permisos, comportamiento del token ERC-20 configurado y riesgos de reentrada antes de operar con activos reales.

## 13. Herramientas de consulta

```bash
# Consultar Chain ID
cast chain-id --rpc-url "$SEPOLIA_RPC_URL"

# Consultar saldo BUSD de una cuenta
cast call 0x6509C8BBdbBBeEe756C6Cd66c2DA2a3e471224cd \
  "balanceOf(address)(uint256)" DIRECCION --rpc-url "$SEPOLIA_RPC_URL"

# Consultar propietario de un NFT
cast call 0x772D607A67f783F2b0E0584ccF3dBEa0d67a28B4 \
  "ownerOf(uint256)(address)" 1 --rpc-url "$SEPOLIA_RPC_URL"
```

---

**CryptoCampo — Proyecto académico de contratos inteligentes.**
