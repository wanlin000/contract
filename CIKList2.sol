// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CIKList {
    address public TA;

    struct Uint512 {
        uint256 high; //用256位的高位和256位的低位，表示512位的证书和公钥（由于solidity最大只能支持256位无符号整数）
        uint256 low;
    }

    struct CIK {
        Uint512 CIK1;  //两个证书
        Uint512 CIK2;
    }
    
    struct APK {
        Uint512 APK1;  //一个公钥
    }

    mapping(uint256 => CIK) cik;
    mapping(uint256 => APK) apk;
    mapping(uint256 => uint256) public apkToTxid;

    constructor() {
        TA = msg.sender;
    }

    function Submit(Uint512 memory CIK1, Uint512 memory CIK2) public returns (address) {
        require(msg.sender == TA, "Only the TA can submit a new CIK");
        uint256 index = uint256(keccak256(abi.encode(CIK1.high, CIK1.low, CIK2.high, CIK2.low)));
        cik[index] = CIK(CIK1, CIK2);
        return msg.sender;
    }

    function Update(Uint512 memory APK1, uint256 txid) public returns (bool) {
        require(msg.sender == TA, "Only the TA can update the mapping");
        uint256 index = uint256(keccak256(abi.encode(APK1.high, APK1.low)));
        apkToTxid[index] = txid;
        return true;
    }
    
    function GetTxid(Uint512 memory APK1) public view returns (uint256) {
        uint256 index = uint256(keccak256(abi.encode(APK1.high, APK1.low)));
        return apkToTxid[index];
    }

    function Check(Uint512 memory CIK1, Uint512 memory CIK2) public view returns (bool) {
        uint256 index = uint256(keccak256(abi.encode(CIK1.high, CIK1.low, CIK2.high, CIK2.low)));
        CIK storage storedCIK = cik[index];
        return (storedCIK.CIK1.high == CIK1.high && storedCIK.CIK1.low == CIK1.low &&
                storedCIK.CIK2.high == CIK2.high && storedCIK.CIK2.low == CIK2.low);
    }

    function Revoke(Uint512 memory CIK1, Uint512 memory CIK2) public returns (bool) {
        require(msg.sender == TA, "Only the TA can revoke a CIK");
        uint256 index = uint256(keccak256(abi.encode(CIK1.high, CIK1.low, CIK2.high, CIK2.low)));
        CIK storage storedCIK = cik[index];
        if (storedCIK.CIK1.high == CIK1.high && storedCIK.CIK1.low == CIK1.low &&
            storedCIK.CIK2.high == CIK2.high && storedCIK.CIK2.low == CIK2.low) {
            storedCIK.CIK1 = Uint512(0, 0);
            storedCIK.CIK2 = Uint512(0, 0);
            return true;
        }
        return false;
    }

    function DeleteMapping(Uint512 memory APK1) public returns (bool) {
        require(msg.sender == TA, "Only the TA can delete the APK-to-txid mapping");
        uint256 index = uint256(keccak256(abi.encode(APK1.high, APK1.low)));
        if (apkToTxid[index] != 0) {
            delete apkToTxid[index];
            return true;
        }
        return false;
    }
}
