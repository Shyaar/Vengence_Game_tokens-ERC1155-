// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IERC1155, IERC1155Receiver} from "./interfaces/ierc1155.sol";
import {Events} from "./lib/events/events.sol";
import {Error} from "./lib/errors/Error.sol";

contract Vengence is IERC1155 {

    uint256 constant public INDEXOF_GOLD = 0;
    uint256 constant public INDEXOF_SILVER = 1;
    uint256 constant public INDEXOF_BATMAN = 2;



    mapping(uint256 => mapping(address => uint256)) internal _balances;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    mapping(uint => uint) public totalSupplyOfTokens;

    mapping(uint256 => string) private _tokenURIs;

    modifier onlyAdmin{
        if (msg.sender != admin) revert Error.NotAdmin();
        _;
    }

    address public admin;

    constructor(){
        admin = msg.sender;
        mint(0, 10_000_000_000, "");
        mint(1, 10_000_000_000, "");
        mint(2, 1, "ipfs://QmaZeqnzihdSPSKkrDufPoBW3QVuYvSC6a5NCi9eVK5jhr/bat.json");
    }


    function balanceOf(address _owner, uint256 _id) external view returns (uint256 myBalance_){
        myBalance_ = _balances[_id][_owner]; 
    }


    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory balanceOfOwners_){

         if (_owners.length != _ids.length) revert Error.AccountIdsMismatch();

        uint256[] memory _batchBalance = new uint256[](_owners.length);

        for(uint256 i = 0; i < _owners.length; ++i){
            if (_owners[i] == address(0)) revert Error.InvalidOwnerAddress();

            _batchBalance[i] = _balances[_ids[i]][_owners[i]];
        }
        balanceOfOwners_ = _batchBalance;
    }


    function setApprovalForAll(address _operator, bool _approved) external{
        _operatorApprovals[msg.sender][_operator] = _approved;

        emit Events.ApprovalForAll(msg.sender, _operator, _approved);
    }


    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return _operatorApprovals[_owner][_operator];
    }


    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external{
        if (_to == address(0)) revert Error.TransferToZeroAddress();
        
        if (_from != msg.sender && !_operatorApprovals[_from][msg.sender]) revert Error.NotApprovedOrSender();

        if (_balances[_id][_from] < _amount) revert Error.InsufficientBalance();
        _balances[_id][_from] -= _amount;
        _balances[_id][_to] += _amount;

        emit Events.TransferSingle(msg.sender, _from, _to, _id, _amount);

        if(_to.code.length >0){
        if (IERC1155Receiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data) != IERC1155Receiver.onERC1155BatchReceived.selector) revert Error.ReceiverRejectedTransfer();
        }

    }


    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external{
        if (_to == address(0)) revert Error.TransferToZeroAddress();
        if (_ids.length != _amounts.length) revert Error.IdsAmountsMismatch();
        if (_from != msg.sender && !_operatorApprovals[_from][msg.sender]) revert Error.NotApprovedOrSender();

        for(uint256 i = 0; i< _ids.length; i++){
            if (_balances[_ids[i]][_from] < _amounts[i]) revert Error.InsufficientBalance();
            _balances[_ids[i]][_from] -= _amounts[i];
            _balances[_ids[i]][_to] += _amounts[i];
        }
        emit Events.TransferBatch(msg.sender, _from, _to, _ids, _amounts);

        if(_to.code.length >0){
        if (IERC1155Receiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data) != IERC1155Receiver.onERC1155BatchReceived.selector) revert Error.ReceiverRejectedTransfer();
        }

    }

    function mint(uint256 _id, uint256 _amount, string memory _uri)  internal {

        if(_id == 0 || _id == 1){
            if (bytes(_uri).length != 0) revert Error.URINotAllowed();

            _balances[_id][msg.sender] += _amount;
            totalSupplyOfTokens[_id] = _amount;

        }

       
         if (_id == 2) {
            if (bytes(_uri).length == 0) revert Error.MissingURI();

            if (_amount >= 2) revert Error.InvalidBatmanAmount();

            if (totalSupplyOfTokens[_id] >= 1) revert Error.BatmanNFTAlreadyExists();

            _tokenURIs[_id] = _uri;
            _balances[_id][msg.sender] += _amount;
            totalSupplyOfTokens[_id] += _amount;

            emit Events.URI(_uri, _id);
        }
    }

    function uri(uint256 id) public view returns (string memory) {
        return _tokenURIs[id]; 
    }
}
