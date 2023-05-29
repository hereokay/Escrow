// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/utils/cryptography/ECDSA.sol";

contract escrow {
    using ECDSA for bytes32;
    uint256 TID = 0; // 0번부터 시작
    address CPO ;
    
    mapping (uint256 => address) EV;
    mapping (uint256 => address) EVSE; // 주유소
    mapping (uint256 => uint256) condition;
    mapping (uint256 => uint256) amount;
    mapping (uint256 => uint256) timeLimit;

    constructor(address _CPO) { 
        CPO = _CPO; // 0x2c7536E3605D9C16a7a3D7b1898e529396a65c23
    }

    function setCPO(address newCPO) public {
        require(msg.sender == CPO);
        CPO = newCPO;
    }

    event checkTID(address _EV, uint TID, uint256 time);

    function deposit (address _EVSE) public payable {
        require(msg.value >= 10**18, "deposit must more than 1 eth");
        EV[TID] = msg.sender; // 사용자
        EVSE[TID] = _EVSE; // 주유소
        amount[TID] = msg.value; // 입금금액
        timeLimit[TID] = block.timestamp; // 시간제한 변수
        
        emit checkTID(msg.sender, TID, timeLimit[TID]);
        TID += 1;
    }

    function verify_sig(uint256 _TID, bytes memory sig) private view {
        require(timeLimit[_TID] + 60*10 > block.timestamp); // 10분이내 거래완료 되어야함
        
        bytes32 txHash = getTxHash(_TID);
        require(_verify_sig(sig, txHash), "invalid sig");
    }

    function check_deposit(uint256 TID) public view returns(address, uint256){
        return (EVSE[TID],amount[TID]);
    }

    function getTxHash(uint256 _TID) public pure returns (bytes32) {
        
        return keccak256(abi.encodePacked(_TID));
    }

    function _verify_sig(bytes memory _sig,bytes32 _txHash) private view returns (bool) {
        bytes32 ethSignedHash = _txHash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(_sig);
        
        bool valid = signer == CPO;

        if (!valid) { return false; }
        return true;
    }

    function withdraw (uint256 _TID, bytes memory sig) public EVSEable(_TID)  {
        require(msg.sender == EVSE[_TID], "you are not EVSE");
        
        // proof 가 제대로 맞는지 체크
        verify_sig(_TID, sig); 
        
        // 인출전 이중인출을 막기위해 condition을 2로 세팅
        condition[_TID] = 2; 
        // 인출하기
        address payable to = payable(msg.sender); 
        to.transfer(amount[_TID]); 
    }

    function refund(uint256 _TID) public {
        require(msg.sender == EV[_TID]); // 거래를 생성한 사람 == 지불한 사람
        require(timeLimit[_TID] + 60*10 <= block.timestamp); // 10분이 지난 거래일 경우

        // 이중인출을 막기위해 condition을 3로 세팅
        condition[_TID] = 3; 
        // 인출하기
        address payable to = payable(msg.sender); 
        to.transfer(amount[_TID]); 
    }
    
    modifier Ownable()
    {
        require(msg.sender == CPO, "Sender not authorized.");
        _;
    }

    modifier EVSEable(uint256 _TID)
    { 
        require(msg.sender == EVSE[_TID], "Sender not authorized.");
        _;
    }
}


contract Hello {

    uint value = 0;
    
    function print() public view returns(uint){
        return value;
    }

}