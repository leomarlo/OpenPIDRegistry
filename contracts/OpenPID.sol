    // SPDX-License-Identifier: GPL-3.0
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
        bytes32[] public pidNodes;  // just for debugging
        
        struct parentPid {
            bytes32 parentNode;
            string parentString;
        }
        
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
            pidNodes.push(pidNode);
            ens.setSubnodeRecord(node, pidLabel, address(this), address(mainResolver), uint64(0));
            mainResolver.setText(pidNode, "URL", URL );
            ens.setApprovalForAll(msg.sender, true);
            
        }
        
        
        
    
        function setRootAddress(bytes32 _openPidRoot) external deployerOnlyOnce {
            openPidRoot = _openPidRoot;
            mainResolver = IResolver(ens.resolver(openPidRoot));
            rootSettable = false;
        }
        
        
        function registerNewMetadataStandard(string memory metadataStandard, string memory URL, string[] memory _categories) external {
            bytes32 _label = keccak256(bytes(metadataStandard));
            bytes32 metadataStandardNode = keccak256(abi.encodePacked(openPidRoot, _label));
            ens.setSubnodeRecord(openPidRoot, _label, address(this), address(mainResolver), uint64(0));
            mainResolver.setText(metadataStandardNode, "URL", URL );
            for (uint256 i=0; i<_categories.length; i++){
                bytes32 _catlabel = keccak256(bytes(_categories[i]));
                bytes32 categoryNode = keccak256(abi.encodePacked(metadataStandardNode, _catlabel));
                ens.setSubnodeRecord(metadataStandardNode, _catlabel, address(this), address(mainResolver), uint64(0));
                parentPids[metadataStandard][_categories[i]].parentNode = categoryNode;
                parentPids[metadataStandard][_categories[i]].parentString = string(abi.encodePacked(_categories[i],'.', metadataStandard));
                pidState[categoryNode] = LCG.iterator({x:233,a:1,c:157,m:277});
            }
        }
        
        function setTextRecord (bytes32 node, string memory key, string memory value) external onlyENSnodeOperators(node) {
        // function setTextRecord (bytes32 node, string memory key, string memory value) external {
            // only operators or owners (i.e. this contract) of the node should call this method!
            mainResolver.setText(node,key,value);
        }
        
        
        // function test() external {
        //     ccaall();
        // }
        
        // address public _test_owner; // = ens.owner(openPidRoot);
        // bool public _test_sender_equal_owner; // = msg.sender==_owner;
        // bool public _test_is_operator; // = ens.isApprovedForAll(_owner, msg.sender);
        // bool public _test_is_this; // = msg.sender==address(this);
        // address public _test_sender;
        
        // function ccaall() public {
            
        //     _test_owner = ens.owner(openPidRoot);
        //     _test_sender_equal_owner = msg.sender==_test_owner;
        //     _test_is_operator = ens.isApprovedForAll(_test_owner, msg.sender);
        //     _test_is_this = msg.sender==address(this);
        //     _test_sender = msg.sender;
        // }
        
        modifier deployerOnlyOnce () {
            require(msg.sender==deployer && rootSettable);
            _;
        }
        
        modifier onlyENSnodeOperators(bytes32 _node) {
            address _owner = ens.owner(_node);
            require(msg.sender==_owner || ens.isApprovedForAll(_owner, msg.sender) || msg.sender==address(this));
            _;
        }
        
        
    }