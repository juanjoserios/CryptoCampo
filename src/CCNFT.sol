// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/* import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; */

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Counters} from "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract CCNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    //EVENTOS
    // indexed: Permiten realizar búsquedas en los registros de eventos.

    // Compra NFTs
    event Buy(address indexed buyer, uint256 indexed tokenId, uint256 value);
    // buyer: La dirección del comprador.
    // tokenId: El ID único del NFT comprado.
    // value: El valor asociado al NFT comprado.

    // Reclamamo NFTs.

    event Claim(address indexed claimer, uint256 indexed tokenId);

    // claimer: La dirección del usuario que reclama los NFTs.
    // tokenId: El ID único del NFT reclamado.

    // Transferencia de NFT de un usuario a otro.

    event Trade(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 value);

    // buyer: La dirección del comprador del NFT.
    // seller: La dirección del vendedor del NFT.
    // tokenId: El ID único del NFT que se transfiere.
    // value: El valor pagado por el comprador al vendedor por el NFT (No indexed).

    // Venta de un NFT.
    event PutOnSale(uint256 indexed tokenId, uint256 price);

    // tokenId: El ID único del NFT que se pone en venta.
    // price: El precio al cual se pone en venta el NFT (No indexed).

    // Estructura del estado de venta de un NFT.

    struct TokenSale {
        bool onSale;
        uint256 price;
    }

    // Biblioteca Counters de OpenZeppelin para manejar contadores de manera segura.
    using Counters for Counters.Counter;

    // Contador para asignar IDs únicos a cada NFT que se crea.
    Counters.Counter private tokenIdTracker;

    // Mapeo del ID de un token (NFT) a un valor específico.
    mapping(uint256 => uint256) public values;

    // Mapeo de un valor a un booleano para indicar si el valor es válido o no.
    mapping(uint256 => bool) public validValues;

    // Mapeo del ID de un token (NFT) a su estado de venta (TokenSale).
    mapping(uint256 => TokenSale) public tokensOnSale;

    // Lista que contiene los IDs de los NFTs que están actualmente en venta.
    uint256[] public listTokensOnSale;

    address public fundsCollector; // Dirección de los fondos de las ventas de los NFTs
    address public feesCollector; // Dirección de las tarifas de transacción (compra y venta de los NFTs)

    bool public canBuy; // Booleano que indica si las compras de NFTs están permitidas.
    bool public canClaim; // Booleano que indica si la reclamación (quitar) de NFTs está permitida.
    bool public canTrade; // Booleano que indica si la transferencia de NFTs está permitida.

    uint256 public totalValue; // Valor total acumulado de todos los NFTs en circulación.
    uint256 public maxValueToRaise; // Valor máximo permitido para recaudar a través de compras de NFTs.

    uint16 public buyFee; // Tarifa aplicada a las compras de NFTs.
    uint16 public tradeFee; // Tarifa aplicada a las transferencias de NFTs.

    uint16 public maxBatchCount; // Límite en la cantidad de NFTs por operación (evitar exceder el límite de gas en una transacción).

    uint32 public profitToPay; // Porcentaje adicional a pagar en las reclamaciones.

    // Referencia al contrato ERC20 manejador de fondos.
    IERC20 public fundsToken;

    // Constructor (nombre y símbolo del NFT).
    constructor() ERC721("CryptoCampo", "CCNFT") {}
    // PUBLIC FUNCTIONS

    // Funcion de compra de NFTs.

    // Parametro value: El valor de cada NFT que se está comprando.
    // Parametro amount: La cantidad de NFTs que se quieren comprar.

    function buy(uint256 value, uint256 amount) external nonReentrant {
        require(canBuy, "Buying is disabled");

        require(amount > 0 && amount <= maxBatchCount, "Invalid amount");

        require(validValues[value], "Invalid NFT value");

        uint256 purchaseValue = value * amount;

        require(totalValue + purchaseValue <= maxValueToRaise, "Maximum fundraising value exceeded");

        totalValue += purchaseValue;

        for (uint256 i = 0; i < amount; i++) {
            tokenIdTracker.increment();

            uint256 tokenId = tokenIdTracker.current();

            values[tokenId] = value;

            _safeMint(_msgSender(), tokenId);

            emit Buy(_msgSender(), tokenId, value);
        }

        if (!fundsToken.transferFrom(_msgSender(), fundsCollector, purchaseValue)) {
            revert("Cannot send funds tokens");
        }

        uint256 feeAmount = (purchaseValue * buyFee) / 10000;

        if (!fundsToken.transferFrom(_msgSender(), feesCollector, feeAmount)) {
            revert("Cannot send fees tokens");
        }
    }

    // Funcion de "reclamo" de NFTs

    // Parámetros: Lista de IDs de tokens de reclamo (utilizar calldata).

    function claim(uint256[] calldata listTokenId) external nonReentrant {
        require(canClaim, "Claiming is disabled");

        require(listTokenId.length > 0 && listTokenId.length <= maxBatchCount, "Invalid claim amount");

        uint256 claimValue = 0;
        TokenSale storage tokenSale;

        for (uint256 i = 0; i < listTokenId.length; i++) {
            require(_exists(listTokenId[i]), "Token does not exist");

            require(ownerOf(listTokenId[i]) == _msgSender(), "Only owner can Claim");

            claimValue += values[listTokenId[i]];
            values[listTokenId[i]] = 0;

            tokenSale = tokensOnSale[listTokenId[i]];
            tokenSale.onSale = false;
            tokenSale.price = 0;

            removeFromArray(listTokenId[i]);

            _burn(listTokenId[i]);

            emit Claim(_msgSender(), listTokenId[i]);
        }

        totalValue -= claimValue;

        uint256 amountToTransfer = claimValue + (claimValue * profitToPay / 10000);

        if (!fundsToken.transferFrom(fundsCollector, _msgSender(), amountToTransfer)) {
            revert("Cannot send funds");
        }
    }

    // Funcion de compra de NFT que esta en venta.

    function trade(uint256 tokenId) external nonReentrant {
        require(canTrade, "Trading is disabled");

        require(_exists(tokenId), "Token does not exist");

        address seller = ownerOf(tokenId);

        require(seller != _msgSender(), "Buyer is the Seller");

        TokenSale storage tokenSale = tokensOnSale[tokenId];

        require(tokenSale.onSale, "Token not On Sale");

        uint256 salePrice = tokenSale.price;

        if (!fundsToken.transferFrom(_msgSender(), seller, salePrice)) {
            revert("Cannot send funds to seller");
        }

        uint256 feeAmount = (salePrice * tradeFee) / 10000;

        if (!fundsToken.transferFrom(_msgSender(), feesCollector, feeAmount)) {
            revert("Cannot send trade fees");
        }

        emit Trade(_msgSender(), seller, tokenId, salePrice);

        _safeTransfer(seller, _msgSender(), tokenId, "");

        tokenSale.onSale = false;
        tokenSale.price = 0;

        removeFromArray(tokenId);
    }

    // Función para poner en venta un NFT.

    function putOnSale(uint256 tokenId, uint256 price) external {
        require(canTrade, "Trading is disabled");

        require(_exists(tokenId), "Token does not exist");

        require(ownerOf(tokenId) == _msgSender(), "Only owner can put token on sale");

        require(price > 0, "Price must be greater than zero");

        TokenSale storage tokenSale = tokensOnSale[tokenId];

        require(!tokenSale.onSale, "Token already on sale");

        tokenSale.onSale = true;
        tokenSale.price = price;

        addToArray(tokenId);

        emit PutOnSale(tokenId, price);
    }

    // SETTERS

    // Utilización del token ERC20 para transacciones.

    function setFundsToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");

        fundsToken = IERC20(_token);
    }

    // Dirección para colectar los fondos de las ventas de NFTs.

    function setFundsCollector(address _address) external onlyOwner {
        require(_address != address(0), "Invalid funds collector");

        fundsCollector = _address;
    }

    // Dirección para colectar las tarifas de transacción.
    function setFeesCollector(address _address) external onlyOwner {
        require(_address != address(0), "Invalid fees collector");

        feesCollector = _address;
    }

    // Porcentaje de beneficio a pagar en las reclamaciones.
    function setProfitToPay(uint32 _profitToPay) external onlyOwner {
        profitToPay = _profitToPay;
    }

    // Función que Habilita o deshabilita la compra de NFTs.
    function setCanBuy(bool _canBuy) external onlyOwner {
        canBuy = _canBuy;
    }

    // Función que Habilita o deshabilita la reclamación de NFTs.
    function setCanClaim(bool _canClaim) external onlyOwner {
        canClaim = _canClaim;
    }

    // Función que Habilita o deshabilita el intercambio de NFTs.
    function setCanTrade(bool _canTrade) external onlyOwner {
        canTrade = _canTrade;
    }

    // Valor máximo que se puede recaudar de venta de NFTs.
    function setMaxValueToRaise(uint256 _maxValueToRaise) external onlyOwner {
        maxValueToRaise = _maxValueToRaise;
    }

    // Función para agregar un valor válido para NFTs.
    function addValidValues(uint256 value) external onlyOwner {
        validValues[value] = true;
    }

    // Función para establecer la cantidad máxima de NFTs por operación.
    function setMaxBatchCount(uint16 _maxBatchCount) external onlyOwner {
        maxBatchCount = _maxBatchCount;
    }

    // Tarifa aplicada a las compras de NFTs.
    function setBuyFee(uint16 _buyFee) external onlyOwner {
        buyFee = _buyFee;
    }

    // Tarifa aplicada a las transacciones de NFTs.
    function setTradeFee(uint16 _tradeFee) external onlyOwner {
        tradeFee = _tradeFee;
    }

    // ARRAYS

    // Verificar duplicados en el array antes de agregar un nuevo valor.

    function addToArray(uint256 value) private {
        uint256 index = find(value);

        if (index == listTokensOnSale.length) {
            listTokensOnSale.push(value);
        }
    }

    // Eliminar un valor del array.

    function removeFromArray(uint256 value) private {
        uint256 index = find(value);

        if (index < listTokensOnSale.length) {
            listTokensOnSale[index] = listTokensOnSale[listTokensOnSale.length - 1];
            listTokensOnSale.pop();
        }
    }

    // Buscar un valor en un array y retornar su índice o la longitud del array si no se encuentra.

    function find(uint256 value) private view returns (uint256) {
        for (uint256 i = 0; i < listTokensOnSale.length; i++) {
            if (listTokensOnSale[i] == value) {
                return i;
            }
        }

        return listTokensOnSale.length;
    }

    // NOT SUPPORTED FUNCTIONS

    // Funciones para deshabilitar las transferencias de NFTs,

    function transferFrom(address, address, uint256) public pure override(ERC721, IERC721) {
        revert("Not Allowed");
    }

    function safeTransferFrom(address, address, uint256) public pure override(ERC721, IERC721) {
        revert("Not Allowed");
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public pure override(ERC721, IERC721) {
        revert("Not Allowed");
    }

    // Compliance required by Solidity

    // Funciones para asegurar que el contrato cumple con los estándares requeridos por ERC721 y ERC721Enumerable.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
