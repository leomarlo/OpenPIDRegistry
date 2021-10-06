// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;
library LCG {
    struct iterator {
        uint x;
        uint a;  
        uint c;
        uint m;
    }
    
    function iterate (iterator storage _i) external {
        _i.x =  (_i.a * _i.x + _i.c) % _i.m;
    }
    
    // https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function convertToString(iterator storage _i) view external returns (string memory _uintAsString) {
        if (_i.x == 0) {
            return "0";
        }
        uint i = _i.x;
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(i - i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            i /= 10;
        }
        
        // maybe fill up the remaining digits with zeros
        return string(bstr);
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
}



// import "./LCG.sol";

// contract OpenPID is ERC721 {
    
contract OpenPID {
    
    using LCG for LCG.iterator;
    
    IENS public ens = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    
    address public deployer;
    
    bool public rootSettable = true;
    
    bytes32 public openPidRoot;
    IResolver public mainResolver;
    string public pid;
    string[] public pids;  
    // bytes32[] public pidNodes;  // just for debugging
    mapping (string => bytes32) public pidNodes;  // somehow not ideal
    string[] public registeredStandards;
    
    struct parentPid {
        bytes32 parentNode;
        string parentString;
    }
    
    struct MetadataInfo {
        bytes32 node;
        string categories;
    }
    
    mapping (string => MetadataInfo) public metadataStandardInfo;
    mapping (string => uint) public version;

    uint256 public pidCount = 0;
    mapping (bytes32 => LCG.iterator) public pidState;
    mapping (string => mapping( string => parentPid)) public parentPids;
    
    constructor () {
        deployer = msg.sender;
    }
    
    function mint(string memory metadataStandard, string memory publicationType, string memory URL) external {
        bytes32 node = parentPids[metadataStandard][publicationType].parentNode;
        
        pidState[node].iterate();
        string memory pidLabelString = pidState[node].convertToString();
        bytes32 pidLabel = keccak256(bytes(pidLabelString));
        pidCount += 1;
        
        pid = string(abi.encodePacked(pidLabelString, '.', parentPids[metadataStandard][publicationType].parentString));
        pids.push(pid);
        
        // register new pid;
        bytes32 pidNode = keccak256(abi.encodePacked(node, pidLabel));
        pidNodes[pid] = pidNode;
        // pidNodes.push(pidNode);
        ens.setSubnodeRecord(node, pidLabel, address(this), address(mainResolver), uint64(0));
        mainResolver.setText(pidNode, "Version 0", URL );
        ens.setApprovalForAll(msg.sender, true);
    }

    function update(string memory _pid, string memory URL) external {
        version[_pid] += 1;
        mainResolver.setText(pidNodes[_pid], _convertVersionToString(version[_pid]), URL );     
    }
    
    
    

    function setRootAddress(bytes32 _openPidRoot) external deployerOnlyOnce {
        openPidRoot = _openPidRoot;
        mainResolver = IResolver(ens.resolver(openPidRoot));
        rootSettable = false;
    }
    
    function registerNewCategory(string memory metadataStandard, string memory _category) external {
        bytes32 _categorylabel = keccak256(bytes(_category));
        bytes32 categoryNode = keccak256(abi.encodePacked(metadataStandardInfo[metadataStandard].node, _categorylabel));
        ens.setSubnodeRecord(metadataStandardInfo[metadataStandard].node, _categorylabel, address(this), address(mainResolver), uint64(0));
        parentPids[metadataStandard][_category].parentNode = categoryNode;
        parentPids[metadataStandard][_category].parentString = string(abi.encodePacked(_category,'.', metadataStandard));                
        // TODO: NOT VIABLE!!! Categories should become a list, but somehow thats not possible inside structs, right?
        metadataStandardInfo[metadataStandard].categories = string(abi.encodePacked(metadataStandardInfo[metadataStandard].categories,', ', _category));
    }
    
    function registerNewMetadataStandard(string memory metadataStandard, string memory URL, string[] memory _categories) external {
        bytes32 _label = keccak256(bytes(metadataStandard));
        bytes32 metadataStandardNode = keccak256(abi.encodePacked(openPidRoot, _label));
        ens.setSubnodeRecord(openPidRoot, _label, address(this), address(mainResolver), uint64(0));
        mainResolver.setText(metadataStandardNode, "URL", URL );
        registeredStandards.push(metadataStandard);
        
        
        // TODO: Find a more efficient waz of doing this.
        string memory categories;
        for (uint256 k=0; k<_categories.length; k++) {
            categories = string(abi.encodePacked(categories,', ', _categories[k]));
        }
        
        
        metadataStandardInfo[metadataStandard] = MetadataInfo({
            node: metadataStandardNode,
            categories: categories
        });
        
        for (uint256 i=0; i<_categories.length; i++){
            bytes32 _catlabel = keccak256(bytes(_categories[i]));
            bytes32 categoryNode = keccak256(abi.encodePacked(metadataStandardNode, _catlabel));
            ens.setSubnodeRecord(metadataStandardNode, _catlabel, address(this), address(mainResolver), uint64(0));
            parentPids[metadataStandard][_categories[i]].parentNode = categoryNode;
            parentPids[metadataStandard][_categories[i]].parentString = string(abi.encodePacked(_categories[i],'.', metadataStandard));
            // pidState[categoryNode] = LCG.iterator({x:233,a:1,c:157,m:277});
            pidState[categoryNode] = LCG.iterator({
                x:233,
                a:6364136223846793005,
                c:1442695040888963407,
                m:(2**64)});
        }
    }
    
    function setTextRecord (bytes32 node, string memory key, string memory value) external onlyENSnodeOperators(node) {
    // function setTextRecord (bytes32 node, string memory key, string memory value) external {
        // only operators or owners (i.e. this contract) of the node should call this method!
        mainResolver.setText(node,key,value);
    }
    
    
    
    modifier deployerOnlyOnce () {
        require(msg.sender==deployer && rootSettable);
        _;
    }
    
    modifier onlyENSnodeOperators(bytes32 _node) {
        address _owner = ens.owner(_node);
        require(msg.sender==_owner || ens.isApprovedForAll(_owner, msg.sender) || msg.sender==address(this));
        _;
    }

    // this is double unfortunately. (also in the library)
    function _convertVersionToString(uint256 x) pure internal returns (string memory _uintAsString) {
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
        return string(abi.encodePacked("Version ", bstr));
    }  
    
    
}