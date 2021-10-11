// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;
library LCGHandler {
    struct iterator {
        uint256 x;
        uint256 a;  
        uint256 c;
        uint256 m;
    }
    
    function iterate (iterator storage _i) external {
        _i.x =  (_i.a * _i.x + _i.c) % _i.m;
    }
    
    
    // https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function convertPidIteratorToString(iterator storage _i) view external returns (string memory _uintAsString) {
        return string(_convertToBytes(_i.x));
    }
    
    // https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function convertVersionToString(uint256 x) pure external returns (string memory _versionAsString) {
        return string(abi.encodePacked("Version ", string(_convertToBytes(x))));
    }
    
    function convertNumberToString(uint256 x) pure external returns (string memory _uintAsString) {
        return string(_convertToBytes(x));
    }
    
    function _convertToBytes(uint256 x) pure internal returns (bytes memory _uintAsBytes) {
        if (x == 0) {
            return "Version 0";
        }
        uint j = x;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (x != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(x - x / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            x /= 10;
        }
        
        // maybe fill up the remaining digits with zeros
        return bstr;
    }  
    
}


// pragma solidity ^0.7.4;
pragma solidity ^0.8.4;
abstract contract ResolverBase {
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    function supportsInterface(bytes4 interfaceID) virtual public pure returns(bool) {
        return interfaceID == INTERFACE_META_ID;
    }

    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}


abstract contract TextResolver is ResolverBase {
    bytes4 constant private TEXT_INTERFACE_ID = 0x59d1d43c;

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    mapping(bytes32=>mapping(string=>string)) texts;

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string calldata key, string calldata value) external authorised(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory) {
        return texts[node][key];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == TEXT_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}



pragma solidity 0.8.4;


interface IOpenPID{
    function isOperator(bytes32, address) view external returns(bool);
}


abstract contract metadataResolverBase is ResolverBase {
    
    
    IOpenPID public opid;
    
    mapping (bytes32=> mapping(string=>uint256)) public version;
    mapping (bytes32=> mapping(string=>mapping(uint256=>string))) internal _metadata;
    
    bytes4 constant private METADATA_CONTENT_INTERFACE_ID = 0x8ca13079;  // bytes4(keccak256('getMetadata(bytes32,string,uint256)'))


    function isAuthorised(bytes32 node) internal override view returns(bool) {
        return msg.sender == address(opid) || opid.isOperator(node, msg.sender);
    }
    
    function _setMetadataEntry(bytes32 node, string memory key, string memory value) virtual internal;
    
    function initialMetadata(bytes32 node, string[] memory keys, string[] memory values) virtual external;
    function updateMetadata(bytes32 node, string[] memory keys, string[] memory values) virtual external;
    
    function getMetadata(bytes32 node, string memory key, uint256 _version) virtual external returns(string calldata);

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == METADATA_CONTENT_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
    
    
}



contract myMetadataResolver is metadataResolverBase, TextResolver {
    
    
    string public typeString = "type";
    string public authorString = "author";
    string public titleString = "title";
    string public urlString = "url";
    
    mapping (string=>bool) public notUpdatetable;
    string[4] public requiredEntries = 
        [
            typeString,
            authorString,
            titleString,
            urlString
        ];
    
    constructor (address _opidAddress) {
        opid = IOpenPID(_opidAddress);
        notUpdatetable[typeString] = true;
        notUpdatetable[authorString] = true;
    }
    
    function _setMetadataEntry(bytes32 node, string memory key, string memory value) override internal {
        version[node][key] += 1;
        _metadata[node][key][version[node][key]] = value;
    }
    
    
    function updateMetadata(bytes32 node, string[] memory keys, string[] memory values) override external  authorised(node) {
        require(keys.length == values.length);
        for (uint256 i; i<keys.length; i++) {
            require( !notUpdatetable[keys[i]] || version[node][keys[i]]==0, "Nonupdatable");
            _setMetadataEntry(node, keys[i], values[i]);
        }
    }
    
    
    function initialMetadata(bytes32 node, string[] memory keys, string[] memory values) override external  authorised(node) {
        require(keys.length == values.length);
        for (uint256 i; i<keys.length; i++) {
            _setMetadataEntry(node, keys[i], values[i]);
        }
        
        // check whether all required keys were set
        for (uint256 i; i<requiredEntries.length; i++) {
            require(version[node][requiredEntries[i]]>0, "missing required key");
        }
    }
    
    
    function getMetadata(bytes32 node, string memory key, uint256 version) override view external authorised(node) returns(string memory) {
        return _metadata[node][key][version];
    }
    
    function supportsInterface(bytes4 interfaceID) public override(metadataResolverBase, TextResolver) pure returns(bool) {
        return metadataResolverBase.supportsInterface(interfaceID) || TextResolver.supportsInterface(interfaceID);
    }
    
    
}



pragma solidity 0.8.4;

interface IENS{

    function setSubnodeRecord(bytes32 node, bytes32 label, address _owner, address _resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address _owner) external returns(bytes32);
    function setResolver(bytes32 node, address _resolver) external;
    function setOwner(bytes32 node, address _owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function resolver(bytes32 node) external view returns (address);
    function owner(bytes32 node) external view returns (address);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address _owner, address operator) external view returns (bool);
}


interface IResolver{
    function setText(bytes32 node, string calldata key, string calldata value) external;
    
    function initialMetadata(bytes32 node, string[] memory keys, string[] memory values) external;
    function updateMetadata(bytes32 node, string[] memory keys, string[] memory values) external;
    
    function getMetadata(bytes32 node, string memory key, uint256 _version) external returns(string calldata);
}



// import "./LCG.sol";
// contract OpenPID is ERC721 {
   
   
    
contract OpenPID {
    
    using LCGHandler for LCGHandler.iterator;
    using LCGHandler for uint256;
    
    IENS public ens = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    
    address public deployer;
    bool public rootSettable = true;
    bytes32 public openPidRoot;
    
    
    uint256 public pidCount = 0;
    uint256 public iterationModulus = 2**64;
    uint256 public iterationSeed;
    
    address[] public registeredResolvers;
    
    LCGHandler.iterator public _LcgIterator = LCGHandler.iterator({
                x:iterationSeed,
                a:6364136223846793005,
                c:1442695040888963407,
                m:iterationModulus});
    
    mapping (bytes32 => mapping(address => bool)) private _isOperator;  // unlike the ens operator, this is an operator only for this pid, not for all domains of the domain owner.
    
    
    
    constructor () {
        deployer = msg.sender;
    }
    
    function setInitialSeed(uint256 _seed) external {
        require(pidCount==0 && _seed < iterationModulus);
        iterationSeed = _seed;
        _LcgIterator.x = _seed;
    }
    
    function mint(address _resolver, string[] memory keys, string[] memory values) external {
        
        _LcgIterator.iterate();
        pidCount += 1;
        bytes32 label = keccak256(bytes(_LcgIterator.convertPidIteratorToString()));
        bytes32 node = keccak256(abi.encodePacked(openPidRoot, label));
        ens.setSubnodeRecord(openPidRoot, label, address(this), _resolver, uint64(0));
        _isOperator[node][msg.sender] = true;
        IResolver(_resolver).initialMetadata(node, keys, values);
    }
    
    
    function lastPID() view external returns(uint256){
        return _LcgIterator.x;
    }
    
    function registerResolver(address resolver) external {
        // TODO: check whether it is an implementer of certain interfaces
        registeredResolvers.push(resolver);
    }
    
    function setOperatorFor(bytes32 pidNode, address newOperator) external onlyOperator(pidNode) {
        _isOperator[pidNode][newOperator] = true;
    }
    
    function withdrawOperatorFrom(bytes32 pidNode, address formerOperator) external onlyOperator(pidNode) {
        _isOperator[pidNode][formerOperator] = false;
    }
    
    function getPIDNodeFromPID(uint256 _pid) view public returns(bytes32) {
        return keccak256(abi.encodePacked(openPidRoot, keccak256(bytes(_pid.convertNumberToString()))));
    }

    function updateFromPID(uint256 _pid, string[] memory keys, string[] memory values) external onlyOperator(getPIDNodeFromPID(_pid)) {
        update(getPIDNodeFromPID(_pid), keys, values);
    }

    function update(bytes32 pidNode, string[] memory keys, string[] memory values) public onlyOperator(pidNode) {
        IResolver(ens.resolver(pidNode)).updateMetadata(pidNode, keys, values);
        
    }
    
    function isOperator (bytes32 pidNode, address operator) view external returns(bool){
        return _isOperator[pidNode][operator];
    }
    
    
    function iterateForTesting(uint256 iterations) external {
        
        require(msg.sender==deployer && iterations>0 && iterations<2**5);
        
        for (uint256 j; j<iterations; j++){
            _LcgIterator.iterate();
        }
        
        pidCount += iterations;
    }
    
    
    
    function setTextRecord (bytes32 pidNode, string memory key, string memory value) external onlyOperator(pidNode) {
    // function setTextRecord (bytes32 node, string memory key, string memory value) external {
        // only operators or owners (i.e. this contract) of the node should call this method!
        IResolver(ens.resolver(pidNode)).setText(pidNode,key,value);
    }
    
    function getMetadataFromPID (uint256 _pid, string memory key, uint256 version) external returns(string memory){
        bytes32 pidNode = getPIDNodeFromPID(_pid);
        return getMetadata (pidNode, key, version);
    }
    
    function getMetadata (bytes32 pidNode, string memory key, uint256 version) public returns(string memory){
        return IResolver(ens.resolver(pidNode)).getMetadata(pidNode, key, version);
    }
    
    
    function transferDomainOwnershipBack() external {
        require(msg.sender==deployer);
        ens.setOwner(openPidRoot, deployer);
    }
    
    
    modifier deployerOnlyOnce () {
        require(msg.sender==deployer && rootSettable);
        _;
    }
    
    
    modifier onlyOperator(bytes32 node) {
        require(_isOperator[node][msg.sender]);
        _;
    }
    
}
