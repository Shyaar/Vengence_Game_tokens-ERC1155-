// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IERC1155, IERC1155Receiver} from "./interfaces/ierc1155.sol";
import {Events} from "./lib/events.sol";

contract Vengence is IERC1155 {

    uint256 constant public INDEXOF_GOLD = 0;
    uint256 constant public INDEXOF_SILVER = 1;
    uint256 constant public INDEXOF_BATMAN = 2;



    mapping(uint256 => mapping(address => uint256)) internal _balances;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    mapping(uint => uint) public totalSupplyOfTokens;

    mapping(uint256 => string) private _tokenURIs;

    modifier onlyAdmin{
        require(msg.sender == admin, "youre not an admin");
        _;
    }

    address public admin;

    constructor(){
        admin = msg.sender;
        mint(0, 10_000_000_000, "");
        mint(1, 10_000_000_000, "");
        mint(2, 1, "ipfs://QmaZeqnzihdSPSKkrDufPoBW3QVuYvSC6a5NCi9eVK5jhr");
    }


    function balanceOf(address _owner, uint256 _id) external view returns (uint256 myBalance_){
        myBalance_ = _balances[_id][_owner]; 
    }


    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory balanceOfOwners_){

         require(_owners.length == _ids.length, "Account to ids mismatch, Please have an equal number of both");

        uint256[] memory _batchBalance = new uint256[](_owners.length);

        for(uint256 i = 0; i < _owners.length; ++i){
            require(_owners[i] != address(0), "Invalid owner address");

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
        
        require(_to != address(0), "The receiving account is an address zero:: cannot transfer to this account");
        
        require (_from == msg.sender || _operatorApprovals[_from][msg.sender], "you dont have approval to make this transfer");

        require(_balances[_id][_from] >0,"insuffcient balance to transfer from");
        _balances[_id][_from] -= _amount;
        _balances[_id][_to] += _amount;

        emit Events.TransferSingle(msg.sender, _from, _to, _id, _amount);

        if(_to.code.length >0){
        require(IERC1155Receiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data) == IERC1155Receiver.onERC1155BatchReceived.selector, "Receiver rejected token transfer");
        }

    }


    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external{
        require(_to != address(0), "The receiving account is an address zero:: cannot transfer to this account");
        require(_ids.length == _amounts.length, "ids and amounts length mismatch");
        require (_from == msg.sender || _operatorApprovals[_from][msg.sender], "you dont have approval to make this transfer");

        for(uint256 i = 0; i< _ids.length; i++){
            _balances[_ids[i]][_from] -= _amounts[i];
            _balances[_ids[i]][_to] += _amounts[i];
        }
        emit Events.TransferBatch(msg.sender, _from, _to, _ids, _amounts);

        if(_to.code.length >0){
        require(IERC1155Receiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data) == IERC1155Receiver.onERC1155BatchReceived.selector, "Receiver rejected token transfer");
        }

    }

    function mint(uint256 _id, uint256 _amount, string memory _uri)  internal {

        if(_id == 0 || _id == 1){
            require(bytes(_uri).length == 0, "you cant set URI for this token");

            _balances[_id][msg.sender] += _amount;
            totalSupplyOfTokens[_id] = _amount;

        }

       
         if (_id == 2) {
            require(bytes(_uri).length > 0, "you need to pass the URI of this NFT");

            require(_amount < 2 , "Batman Nft can only have 1");

            require(totalSupplyOfTokens[_id] < 1, "Batman Nft already Exist");

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
