pragma solidity ^0.4.21;
//------------------------------------------------------------------------------
/// @title IPC Access Control
/// @dev defines access modifiers for God, Exec, Admin, and Developer access
/// defines functions to assign access levels to addresses. To avoid conflicts
/// of interest, an address with any of these levels of access cannot own IPCs.
//------------------------------------------------------------------------------
contract IpcAccessControl {
 address ipcGod; // Assigns Exec, Admin, and Cashier addresses
 address ipcExec; // Manages top-level variable modification
 address ipcCashier; // Address to where money is sent
 mapping (uint=>address) indexToAdmin; // list of admin-level access
 mapping (address=>bool) ipcDeveloper; // developer-level access
 uint totalAdmins;
 uint public totalDevelopers;
 bool locked; // protects against re-entrancy attacks
 modifier onlyIpcGod() {
 require (msg.sender == ipcGod);
 _;
 }
 modifier onlyExecOrHigher() {
 require (msg.sender == ipcExec || msg.sender == ipcGod);
 _;
 }
 modifier onlyAdminOrHigher() {
 require (_checkIfAdmin(msg.sender) || msg.sender == ipcExec || msg.sender ==
ipcGod);
 _;
 }
 modifier onlyDeveloper() {
 require(ipcDeveloper[msg.sender]);
 _;
 }
 modifier noHigherAccess(address _address) {
 require(_checkIfAdmin(_address) == false &&
 _address != ipcExec &&

 _address != ipcGod);
 _;
 }
 // protects payable functions against re-entrancy attacks
 modifier noReentrancy() {
 require(!locked);
 locked = true;
 _;
 locked = false;
 }
 //--------------------------------------------------------------------------
 // FUNCTIONS - high to low clearance
 //--------------------------------------------------------------------------
 function renounceGodhood(address _newGod) external onlyIpcGod {
 ipcGod = _newGod;
 }
 function setExec(address _newExec) external onlyIpcGod {
 ipcExec = _newExec;
 }
 function setCashier(address _newCashier) external onlyIpcGod {
 ipcCashier = _newCashier;
 }
 function addAdmin(address _newAdmin) external onlyExecOrHigher {
 indexToAdmin[totalAdmins] = _newAdmin;
 totalAdmins++;
 }
 function removeAdmin(address _adminToRemove) external onlyExecOrHigher {
 for (uint i = 0; i < totalAdmins; ++i) {
 if (indexToAdmin[i] == _adminToRemove) {
 if (i != totalAdmins - 1) {
 address swapAddress = indexToAdmin[totalAdmins - 1];
 indexToAdmin[i] = swapAddress;
 }
 totalAdmins--;
 }
 }

 }
 function getAllPositions() external view onlyExecOrHigher returns (address[]) {
 address[] memory positions = new address[](totalAdmins + 3);
 positions[0] = ipcGod;
 positions[1] = ipcExec;
 positions[2] = ipcCashier;
 for (uint i = 3; i < positions.length; ++i) {
 positions[i] = indexToAdmin[i];
 }
 return positions;
 }
 function getAdmins() external view onlyAdminOrHigher returns (address[]) {
 address[] memory admins = new address[](totalAdmins);
 for (uint i = 0; i < totalAdmins; ++i) {
 admins[i] = indexToAdmin[i];
 }
 return admins;
 }
 function changeDeveloperStatus(address developer, bool value) external
onlyExecOrHigher {
 require(ipcDeveloper[developer] != value);
 if (value == true) {
 totalDevelopers++;
 } else {
 totalDevelopers--;
 }
 ipcDeveloper[developer] = value;
 }
 // withdraws money somehow stuck in the contract
 function withdraw() external onlyAdminOrHigher {
 ipcCashier.transfer(address(this).balance);
 }
 function _checkIfAdmin(address _address) internal view returns(bool) {
 for(uint i = 0; i < totalAdmins; ++i){
 if (_address == indexToAdmin[i]) {
 return true;
 }

 }
 return false;
 }
}
//------------------------------------------------------------------------------
/// @title IPC Release Control
/// @dev Keeps track of the number and price of the IPCs released per tranche
/// and dictates when the next tranche gets released
//------------------------------------------------------------------------------
contract IpcReleaseControl is IpcAccessControl {
 bool autoTrancheRelease = true; // whether tranches release by themselves
 uint128 public totalIpcs; // all ipcs in existence
 uint trancheSize = 1000; // number of IPCs to be created per release
 uint ipcCap; // equal to previous ipcCap + trancheSize
 uint priceIncreasePerTrancheInCents = 1; // how much more each IPC costs per tranche
 uint public ipcPriceInCents = 25;
 function changeTrancheSize(uint _newSize) external onlyExecOrHigher {
 require (_newSize > 0);
 trancheSize = _newSize;
 }
 function changePriceIncreasePerTranche(uint _newPriceIncrease) external
onlyExecOrHigher {
 priceIncreasePerTrancheInCents = _newPriceIncrease;
 }
 function releaseNewTranche() public {
 if(autoTrancheRelease == false) {
 require (msg.sender == ipcExec || msg.sender == ipcGod);
 }
 require(totalIpcs >= ipcCap);
 ipcCap += trancheSize;
 ipcPriceInCents += priceIncreasePerTrancheInCents;
 }
 function setAutoTrancheRelease(bool value) external onlyExecOrHigher {
 autoTrancheRelease = value;

 }
}
//------------------------------------------------------------------------------
/// @title ERC-165 Standard Interface Detection
/// @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
/// Note: the ERC-165 identifier for this interface is 0x01ffc9a7
//------------------------------------------------------------------------------
interface ERC165 {
 /// @notice Query if a contract implements an interface
 /// @param _interfaceId The interface identifier, as specified in ERC-165
 /// @dev Interface identification is specified in ERC-165. This function
 /// uses less than 30,000 gas.
 /// @return `true` if the contract implements `interfaceId` and
 /// `interfaceId` is not 0xffffffff, `false` otherwise
 function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}
//------------------------------------------------------------------------------
/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
/// Note: the ERC-165 identifier for this interface is 0x6466353c
//------------------------------------------------------------------------------
interface ERC721 {
 // Events
 /// @dev This emits when ownership of any NFT changes by any mechanism.
 /// This event emits when NFTs are created (`from` == 0) and destroyed
 /// (`to` == 0). Exception: during contract creation, any number of NFTs
 /// may be created and assigned without emitting Transfer. At the time of
 /// any transfer, the approved address for that NFT (if any) is reset to none.
 event Transfer(address indexed _from, address indexed _to, uint256 indexed
_tokenId);
 /// @dev This emits when the approved address for an NFT is changed or
 /// reaffirmed. The zero address indicates there is no approved address.
 /// When a Transfer event emits, this also indicates that the approved
 /// address for that NFT (if any) is reset to none.
 event Approval(address indexed _owner, address indexed _approved, uint256 indexed
_tokenId);

 /// @dev This emits when an operator is enabled or disabled for an owner.
 /// The operator can manage all NFTs of the owner.
 event ApprovalForAll(address indexed _owner, address indexed _operator, bool
_approved);
 /// @notice Count all NFTs assigned to an owner
 /// @dev NFTs assigned to the zero address are considered invalid, and this
 /// function throws for queries about the zero address.
 /// @param _owner An address for whom to query the balance
 /// @return The number of NFTs owned by `_owner`, possibly zero
 function balanceOf(address _owner) external view returns (uint256 balance);
 /// @notice Find the owner of an NFT
 /// @param _tokenId The identifier for an NFT
 /// @dev NFTs assigned to zero address are considered invalid, and queries
 /// about them do throw.
 /// @return The address of the owner of the NFT
 function ownerOf(uint256 _tokenId) external view returns (address owner);
 /// @notice Transfers the ownership of an NFT from one address to another address
 /// @dev Throws unless `msg.sender` is the current owner, an authorized
 /// operator, or the approved address for this NFT. Throws if `_from` is
 /// not the current owner. Throws if `_to` is the zero address. Throws if
 /// `_tokenId` is not a valid NFT. When transfer is complete, this function
 /// checks if `_to` is a smart contract (code size > 0). If so, it calls
 /// `onERC721Received` on `_to` and throws if the return value is not
 /// `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
 /// @param _from The current owner of the NFT
 /// @param _to The new owner
 /// @param _tokenId The NFT to transfer
 /// @param data Additional data with no specified format, sent in call to `_to`
 function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes
data) external payable;
 /// @notice Transfers the ownership of an NFT from one address to another address
 /// @dev This works identically to the other function with an extra data parameter,
 /// except this function just sets data to []
 /// @param _from The current owner of the NFT
 /// @param _to The new owner
 /// @param _tokenId The NFT to transfer
 function safeTransferFrom(address _from, address _to, uint256 _tokenId) external

payable;
 /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
 /// TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
 /// THEY MAY BE PERMANENTLY LOST
 /// @dev Throws unless `msg.sender` is the current owner, an authorized
 /// operator, or the approved address for this NFT. Throws if `_from` is
 /// not the current owner. Throws if `_to` is the zero address. Throws if
 /// `_tokenId` is not a valid NFT.
 /// @param _from The current owner of the NFT
 /// @param _to The new owner
 /// @param _tokenId The NFT to transfer
 function transferFrom(address _from, address _to, uint256 _tokenId) external
payable;
 /// @notice Set or reaffirm the approved address for an NFT
 /// @dev The zero address indicates there is no approved address.
 /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
 /// operator of the current owner.
 /// @param _approved The new approved NFT controller
 /// @param _tokenId The NFT to approve
 function approve(address _approved, uint256 _tokenId) external payable;
 /// @notice Enable or disable approval for a third party ("operator") to manage
 /// all your asset.
 /// @dev Emits the ApprovalForAll event
 /// @param _operator Address to add to the set of authorized operators.
 /// @param _approved True if the operators is approved, false to revoke approval
 function setApprovalForAll(address _operator, bool _approved) external;
 /// @notice Get the approved address for a single NFT
 /// @dev Throws if `_tokenId` is not a valid NFT
 /// @param _tokenId The NFT to find the approved address for
 /// @return The approved address for this NFT, or the zero address if there is none
 function getApproved(uint256 _tokenId) external view returns (address);
 /// @notice Query if an address is an authorized operator for another address
 /// @param _owner The address that owns the NFTs
 /// @param _operator The address that acts on behalf of the owner
 /// @return True if `_operator` is an approved operator for `_owner`, false otherwise

 function isApprovedForAll(address _owner, address _operator) external view returns
(bool);
}
//------------------------------------------------------------------------------
/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
/// Note: the ERC-165 identifier for this interface is 0x780e9d63
//------------------------------------------------------------------------------
interface ERC721Enumerable /* is ERC721 */ {
 /// @notice Count NFTs tracked by this contract
 /// @return A count of valid NFTs tracked by this contract, where each one of
 /// them has an assigned and queryable owner not equal to the zero address
 function totalSupply() external view returns (uint256);
 /// @notice Enumerate valid NFTs
 /// @dev Throws if `_index` >= `totalSupply()`.
 /// @param _index A counter less than `totalSupply()`
 /// @return The token identifier for the `_index`th NFT,
 /// (sort order not specified)
 function tokenByIndex(uint256 _index) external view returns (uint256);
 /// @notice Enumerate NFTs assigned to an owner
 /// @dev throws if __owner is the zero address
 /// @param _owner An address to query for owned NFTs
 /// @return The token identifiers for all NFTs assigned to _owner in order of creation
 function tokensOfOwner(address _owner) external view returns (uint256[]);
 /// @notice Get the token Id of the '_index'th NFT assigned to an owner
 /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
 /// `_owner` is the zero address, representing invalid NFTs.
 /// @param _owner An address where we are interested in NFTs owned by them
 /// @param _index A counter less than `balanceOf(_owner)`
 /// @return The token identifier for the `_index`th NFT assigned to `_owner`
 function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns
(uint256 _tokenId);
}
/// @title Metadata extension to ERC-721 interface

/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
/// Note: the ERC-165 identifier for this interface is 0x5b5e139f
interface ERC721Metadata {
 /// @dev ERC-165 (draft) interface signature for ERC721
 // bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata = // 0x2a786f11
 // bytes4(keccak256('name()')) ^
 // bytes4(keccak256('symbol()')) ^
 // bytes4(keccak256('deedUri(uint256)'));
 /// @notice A descriptive name for a collection of deeds managed by this
 /// contract
 /// @dev Wallets and exchanges MAY display this to the end user.
 function name() external pure returns (string _name);
 /// @notice An abbreviated name for deeds managed by this contract
 /// @dev Wallets and exchanges MAY display this to the end user.
 function symbol() external pure returns (string _symbol);
 /// @notice A distinct URI (RFC 3986) for a given token.
 /// @dev If:
 /// * The URI is a URL
 /// * The URL is accessible
 /// * The URL points to a valid JSON file format (ECMA-404 2nd ed.)
 /// * The JSON base element is an object
 /// then these names of the base element SHALL have special meaning:
 /// * "name": A string identifying the item to which `_tokenId` grants
 /// ownership
 /// * "description": A string detailing the item to which `_tokenId` grants
 /// ownership
 /// * "image": A URI pointing to a file of image/* mime type representing
 /// the item to which `_tokenId` grants ownership
 /// Wallets and exchanges MAY display this to the end user.
 /// Consider making any images at a width between 320 and 1080 pixels and
 /// aspect ratio between 1.91:1 and 4:5 inclusive.
 function tokenURI(uint256 _tokenId) external view returns (string);
}
//------------------------------------------------------------------------------
/// @title Coin Market Price Smart Contract
/// @dev see https://github.com/hunterlong/marketprice/blob/master/README.md

/// Updates every 2 hours
//------------------------------------------------------------------------------
interface MarketPrice {
 function ETH(uint _id) external constant returns (uint256);
 function USD(uint _id) external constant returns (uint256);
 function EUR(uint _id) external constant returns (uint256);
 function GBP(uint _id) external constant returns (uint256);
 function updatedAt(uint _id) external constant returns (uint);
}
//------------------------------------------------------------------------------
/// @title IPC Creation
/// @dev Defines all ownership data structures and handles all IPC creation
/// defines ERC-721 Enumerable's ownership queries
//------------------------------------------------------------------------------
contract IpcCreation is IpcReleaseControl, ERC165, ERC721, ERC721Enumerable {
 /// @dev This emits when an IPC is created by any mechanism. Exception:
 /// during contract creation in the event of an update, existing IPCs
 /// will be created and assigned without emitting Created.
 event Created(uint tokenId, address indexed owner, string name);
 /// @dev This emits when an IPC is fully substantiated with dna, attributes,
 /// and a time of birth.
 event Substantiated(uint tokenId, bytes32 dna, bytes32 attributes);
 /// @dev This emits when an IPC's dna is modified
 event DnaModified(uint indexed tokenId, bytes32 to);
 // currency converter
 MarketPrice priceConverter;
 // contains all IPC information
 struct Ipc {
 string name;
 bytes32 attributeSeed;
 bytes32 dna;
 uint128 experience;
 uint128 timeOfBirth;
 }

 Ipc[] public Ipcs; // array of IPCs
 mapping (uint => address) public ipcToOwner; // IPC to owner address
 mapping (address => uint) public ownerIpcCount; // how many IPCs an address owns
 mapping (uint => uint) ipcSeedToCustomizationPrice; // the price to customize an IPC seed
 mapping (uint => bool) ipcToAdminAuthorization; // whether or not an admins can modify IPC
 uint public customizationPriceMultiplier = 4;
 uint nonce = 0;
 modifier onlyOwnerOrAdmin(uint _costInCents, uint _ipcId) {
 uint costInWei = _convertCentsToWei(_costInCents);
 require (
 msg.sender == ipcToOwner[_ipcId] && msg.value >= costInWei ||
 (ipcToAdminAuthorization[_ipcId] &&
 (_checkIfAdmin(msg.sender) ||
 msg.sender == ipcExec ||
 msg.sender == ipcGod))
 );
 _;
 }
 // forward declaration
 function setIpcPrice(uint _ipcId, uint _newPrice) public onlyOwnerOrAdmin(0,
_ipcId);
 //--------------------------------------------------------------------------
 // IPC ADMIN FUNCTIONS
 //--------------------------------------------------------------------------
 function changeCustomizationMultiplier(uint _newMultiplier) external
onlyExecOrHigher {
 customizationPriceMultiplier = _newMultiplier;
 }
 function updateMarketPriceContract(address _newAddress) external onlyExecOrHigher
{
 priceConverter = MarketPrice(_newAddress);
 }

 function createAndAssignRandomizedIpc(
 string _name,
 uint _price,
 address _owner
 ) external onlyAdminOrHigher noHigherAccess(_owner) {
 require(bytes(_name).length <= 32 && totalIpcs < ipcCap);
 _makeIpc(_price, _owner, _name, _generateRandomNumber(),
_generateRandomNumber(), uint128(now));
 emit Substantiated(totalIpcs, Ipcs[totalIpcs - 1].dna, Ipcs[totalIpcs -
1].attributeSeed);
 if (totalIpcs >= ipcCap && autoTrancheRelease) {
 releaseNewTranche();
 }
 }
 function createAndAssignIpcSeed(
 string _name,
 uint _price,
 address _owner
 ) external onlyAdminOrHigher noHigherAccess(_owner) {
 require(bytes(_name).length <= 32 && totalIpcs < ipcCap);
 _makeIpc(_price, _owner, _name, 0, 0, 0);
 ipcSeedToCustomizationPrice[totalIpcs] = ipcPriceInCents *
customizationPriceMultiplier;
 if (totalIpcs >= ipcCap && autoTrancheRelease) {
 releaseNewTranche();
 }
 }
 //--------------------------------------------------------------------------
 // USER FUNCTIONS
 //--------------------------------------------------------------------------
 /// @notice Create a fully substantiated IPC with randomized attributes and dna
 /// @dev Throws if name is longer than 32 bytes. Throws if msg.value is too low.
 /// Throws if msg.sender is an admin, ipcExec, or ipcGod.
 /// @param _name Name to assign to the IPC. The longer the name, the more gas needed
 /// @param _price Initial buy price for the IPC. Price calculated in USD cents.
 function createRandomizedIpc(
 string _name,
 uint _price

 ) external payable noReentrancy noHigherAccess(msg.sender) {
 require(bytes(_name).length <= 32 && totalIpcs < ipcCap);
 uint ipcPriceInWei = _convertCentsToWei(ipcPriceInCents);
 require (msg.value >= ipcPriceInWei);
 _makeIpc(_price, msg.sender, _name, _generateRandomNumber(),
_generateRandomNumber(), uint128(now));
 emit Substantiated(totalIpcs, Ipcs[totalIpcs - 1].dna, Ipcs[totalIpcs -
1].attributeSeed);
 msg.sender.transfer(msg.value - ipcPriceInWei);
 ipcCashier.transfer(ipcPriceInWei);
 if (totalIpcs >= ipcCap && autoTrancheRelease) {
 releaseNewTranche();
 }
 }
 /// @notice Create an unsubstantiated IPC Seed with no attributes or dna
 /// @dev Throws if name is longer than 32 bytes. Throws if msg.value is too low.
 /// Throws if msg.sender is an admin, ipcExec, or ipcGod.
 /// @param _name Name to assign to the IPC. The longer the name, the more gas needed
 /// @param _price Initial buy price for the IPC. Price calculated in USD cents.
 function createIpcSeed(
 string _name,
 uint _price
 ) external payable noReentrancy noHigherAccess(msg.sender) {
 require(bytes(_name).length <= 32 && totalIpcs < ipcCap);
 uint ipcPriceInWei = _convertCentsToWei(ipcPriceInCents);
 require (msg.value >= ipcPriceInWei);
 _makeIpc(_price, msg.sender, _name, 0, 0, 0);
 ipcSeedToCustomizationPrice[totalIpcs] = ipcPriceInCents *
customizationPriceMultiplier;
 msg.sender.transfer(msg.value - ipcPriceInWei);
 ipcCashier.transfer(ipcPriceInWei);
 if (totalIpcs >= ipcCap && autoTrancheRelease) {
 releaseNewTranche();
 }
 }
 /// @notice Rolls attributes on an IPC Seed. Does not substantiate.
 /// @dev Throws unless `msg.sender` is the current owner or an authorized IPC administrator.
 /// Throws if attributes were already rolled.

 /// @param _ipcId IPC Identifier to roll attributes
 function rollAttributes(uint _ipcId) external onlyOwnerOrAdmin(0, _ipcId) {
 Ipc storage myIpc = Ipcs[_ipcId - 1];
 require (myIpc.attributeSeed == 0); // can only roll attributes once
 myIpc.attributeSeed = _generateRandomNumber();
 }
 /// @notice Rolls custom dna on an IPC Seed. If attributes not rolled, roll attributes. Substantiates.
 /// @dev Throws unless `msg.sender` is the current owner or an authorized IPC administrator.
 /// Throws if msg.value is too low. Throws if IPC is already substantiated.
 /// @param _ipcId IPC Identifier for IPC to customize DNA
 /// @param _dna A custom bytes32
 function customizeDna(
 uint _ipcId,
 bytes32 _dna
 ) public payable noReentrancy
onlyOwnerOrAdmin(ipcSeedToCustomizationPrice[_ipcId], _ipcId) {
 Ipc storage myIpc = Ipcs[_ipcId - 1];
 require (myIpc.timeOfBirth == 0);
 myIpc.timeOfBirth = uint128(now);
 myIpc.dna = _dna;
 if (myIpc.attributeSeed == 0) {
 myIpc.attributeSeed = _generateRandomNumber();
 }
 emit Substantiated(totalIpcs, Ipcs[totalIpcs - 1].dna, Ipcs[totalIpcs -
1].attributeSeed);
 msg.sender.transfer(msg.value - ipcSeedToCustomizationPrice[_ipcId]);
 ipcCashier.transfer(ipcSeedToCustomizationPrice[_ipcId]);
 }
 /// @notice Rolls randomized dna on an IPC Seed. If attributes not rolled,
 /// rolls attributes. Substantiates.
 /// @dev Throws unless `msg.sender` is the current owner or an authorized IPC administrator.
 /// Throws if IPC is already substantiated.
 /// @param _ipcId IPC Identifier for IPC to randomize DNA
 function randomizeDna(uint _ipcId) external onlyOwnerOrAdmin(0, _ipcId) {
 Ipc storage myIpc = Ipcs[_ipcId - 1];
 require (myIpc.timeOfBirth == 0);
 myIpc.timeOfBirth = uint128(now);

 myIpc.dna = _generateRandomNumber();
 if (myIpc.attributeSeed == 0) {
 myIpc.attributeSeed = _generateRandomNumber();
 }
 emit Substantiated(totalIpcs, Ipcs[totalIpcs - 1].dna, Ipcs[totalIpcs -
1].attributeSeed);
 }
 /// @notice Changes whether or not an admin is authorized to make changes to an IPC
 function changeAdminAuthorization(uint _ipcId, bool _authorization) external
onlyOwnerOrAdmin(0, _ipcId) {
 ipcToAdminAuthorization[_ipcId] = _authorization;
 }
 //--------------------------------------------------------------------------
 // ERC-721 FUNCTIONS
 //--------------------------------------------------------------------------
 function totalSupply() external view returns (uint) {
 return totalIpcs;
 }
 function tokenByIndex(uint _index) external view returns (uint) {
 require (_index < totalIpcs);
 return _index + 1; // IPC ID is ALWAYS index + 1
 }
 function balanceOf(address _owner) external view returns (uint) {
 require (_owner != 0);
 return ownerIpcCount[_owner];
 }
 function tokensOfOwner(address _owner) external view returns (uint[]) {
 require(ownerIpcCount[_owner] > 0);
 uint counter = 0;
 uint[] memory result = new uint[](ownerIpcCount[_owner]);
 for (uint i = 1; i <= Ipcs.length; i++) {
 if(ipcToOwner[i] == _owner) {
 result[counter] = i;
 counter++;
 }
 }

 return result;
 }
 function tokenOfOwnerByIndex(address _owner, uint _index) external view returns
(uint) {
 require (_index <= ownerIpcCount[_owner]);
 uint counter = 0;
 for (uint i = 0; i < Ipcs.length; i++) {
 if (ipcToOwner[i] == _owner) {
 if (counter == _index) {
 return i;
 } else {
 counter++;
 }
 }
 }
 }
 function ownerOf(uint _tokenId) external view returns (address owner) {
 owner = ipcToOwner[_tokenId];
 }
 //--------------------------------------------------------------------------
 // INTERNAL FUNCTIONS
 //--------------------------------------------------------------------------
 function _generateRandomNumber() internal returns (bytes32) {
 nonce++;
 return keccak256(now, msg.sender, nonce);
 }
 function _makeIpc(
 uint _price,
 address _owner,
 string _name,
 bytes32 _dna,
 bytes32 _attributeSeed,
 uint128 _timeOfBirth
 ) internal {
 uint id = Ipcs.push(Ipc(_name, _attributeSeed, _dna, 0, _timeOfBirth));
 ipcToOwner[id] = _owner;
 ownerIpcCount[_owner]++;
 ipcToAdminAuthorization[id] = true; // default admin access

 setIpcPrice(id, _price);
 emit Created(id, _owner, _name);
 emit Transfer(0, _owner, id); // send the Transfer event
 totalIpcs++;
 }
 function _convertCentsToWei(uint centsAmount) internal view returns(uint) {
 uint ethCent = priceConverter.USD(0); // $0.01 worth of wei
 return (ethCent * centsAmount); // centsAmount worth of wei
 }
}
/// @dev Note: the ERC-165 identifier for this interface is 0xf0b9e5ba
interface ERC721TokenReceiver {
 /// @notice Handle the receipt of an NFT
 /// @dev The ERC721 smart contract calls this function on the recipient
 /// after a `transfer`. This function MAY throw to revert and reject the
 /// transfer. This function MUST use 50,000 gas or less. Return of other
 /// than the magic value MUST result in the transaction being reverted.
 /// Note: the contract address is always the message sender.
 /// @param _from The sending address
 /// @param _tokenId The NFT identifier which is being transfered
 /// @param data Additional data with no specified format
 /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
 /// unless throwing
 function onERC721Received(address _from, uint256 _tokenId, bytes data) external
returns(bytes4);
}
//------------------------------------------------------------------------------
/// @title IPC Marketplace
/// @dev Defines ownership transfer functions and owner-chosen pricing information.
/// Transfers can be done in three different ways: safeTransferFrom, transferFrom,
/// and buyIpc.
//------------------------------------------------------------------------------
contract IpcMarketplace is IpcCreation {
 /// @dev Emits whenever an IPC is bought using the buyIpc function
 event Bought(uint indexed _tokenId, address _seller, address indexed _buyer, uint
price);

 /// @dev Emits whenever the price of an IPC changes. Does not emit for beneficiary price change
 event PriceChanged(uint indexed _tokenId, uint from, uint to);
 struct IpcMarketInfo {
 uint32 sellPrice;
 uint32 beneficiaryPrice;
 address beneficiaryAddress;
 address approvalAddress; // used for ERC721-required approval and takeOwnership functions
 }
 mapping (uint => IpcMarketInfo) public ipcToMarketInfo;
 mapping (address => mapping (address => bool)) ownerToOperator;
 uint public maxIpcPrice = 100000000; // 1 million
 function setMaxIpcPrice(uint _newPrice) external onlyExecOrHigher {
 maxIpcPrice = _newPrice;
 }
 /// @notice Change the sell price of an owned IPC
 /// @dev throws unless msg.sender is the owner of the IPC or an IPC administrator
 /// @param _ipcId The IPC Identifier for the IPC whose price is changing
 /// @param _newPrice The new price for the IPC
 function setIpcPrice(uint _ipcId, uint _newPrice) public onlyOwnerOrAdmin(0,
_ipcId) {
 uint from = ipcToMarketInfo[_ipcId].sellPrice;
 if (_newPrice > maxIpcPrice) {
 _newPrice = maxIpcPrice;
 }
 ipcToMarketInfo[_ipcId].sellPrice = uint32(_newPrice);
 emit PriceChanged(_ipcId, from, _newPrice);
 }
 /// @notice Gives a beneficiary address a discounted or inflated price.
 /// @dev There may only be one beneficiary at a time. Throws unless msg.sender
 /// is the owner of the IPC or an approved IPC administrator.
 /// @param _ipcId The IPC Identifier for the IPC to approve a beneficiary
 /// @param _beneficiaryAddress The beneficiary's wallet address
 /// @param _beneficiaryPrice The special price for the beneficiary
 function setSpecialPriceForAddress(

 uint _ipcId,
 address _beneficiaryAddress,
 uint _beneficiaryPrice
 ) external onlyOwnerOrAdmin(0, _ipcId) {
 ipcToMarketInfo[_ipcId].beneficiaryPrice = uint32(_beneficiaryPrice);
 ipcToMarketInfo[_ipcId].beneficiaryAddress = _beneficiaryAddress;
 }
 /// @notice Obtains ownership of an ipc. Must send at least the buyout price.
 /// @dev Throws unless _ipcId is valid. Throws if msg.value is too low.
 /// Buying sets beneficiaryAddress to 0 address. Emits Transfer event. Emits
 /// Bought event.
 /// @param _ipcId The IPC Identifier for the IPC to be bought
 /// @param _newPrice The new price of the IPC once bought
 function buyIpc(uint _ipcId, uint _newPrice) public payable noReentrancy {
 require(_ipcId > 0 && _ipcId <= totalIpcs);
 IpcMarketInfo storage ipcToBuy = ipcToMarketInfo[_ipcId];
 uint priceInCents;
 uint priceInWei;
 if (msg.sender == ipcToBuy.beneficiaryAddress) {
 priceInCents = ipcToBuy.beneficiaryPrice;
 } else {
 priceInCents = ipcToBuy.sellPrice;
 }
 priceInWei = _convertCentsToWei(priceInCents);
 require (msg.value >= priceInWei);
 address seller = ipcToOwner[_ipcId];
 _transferOwnership(msg.sender, seller, _ipcId);
 emit Bought(_ipcId, seller, msg.sender, priceInCents); // send buy event
 ipcToBuy.sellPrice = uint32(_newPrice);
 msg.sender.transfer(msg.value - priceInWei); // send the excess value back
 seller.transfer(priceInWei); // send the rest to the seller
 }
 //--------------------------------------------------------------------------
 // ERC721-required transfer functions
 //--------------------------------------------------------------------------
 function safeTransferFrom(
 address _from,
 address _to,
 uint256 _tokenId,

 bytes data
 ) external payable noHigherAccess(_to) {
 require (
 msg.sender == ipcToOwner[_tokenId] || // IPC owner
 msg.sender == ipcToMarketInfo[_tokenId].approvalAddress || // Approved address
 ownerToOperator[ipcToOwner[_tokenId]][msg.sender] == true // Approved operator
 );
 require (_tokenId != 0 && _tokenId <= totalIpcs);
 require (_from == ipcToOwner[_tokenId]);
 require (_to != 0);
 if (msg.sender == ipcToMarketInfo[_tokenId].approvalAddress) {
 require (_to == msg.sender);
 }
 _transferOwnership(_to, _from, _tokenId);
 if (_isContract(_to)) {
 ERC721TokenReceiver tokenReceiver = ERC721TokenReceiver(_to);
 bytes4 returnValue = tokenReceiver.onERC721Received(_from, _tokenId,
data);
 require (returnValue ==
bytes4(keccak256("onERC721Received(address,uint256,bytes)")));
 }
 }
 function safeTransferFrom(
 address _from,
 address _to,
 uint256 _tokenId
 ) external payable noHigherAccess(_to) {
 require (
 msg.sender == ipcToOwner[_tokenId] || // IPC owner
 msg.sender == ipcToMarketInfo[_tokenId].approvalAddress || // Approved address
 ownerToOperator[ipcToOwner[_tokenId]][msg.sender] == true // Approved operator
 );
 require (_tokenId != 0 && _tokenId <= totalIpcs);
 require (_from == ipcToOwner[_tokenId]);
 require (_to != 0);
 if (msg.sender == ipcToMarketInfo[_tokenId].approvalAddress) {
 require (_to == msg.sender);

 }
 bytes memory data;
 _transferOwnership(_to, _from, _tokenId);
 if (_isContract(_to)) {
 ERC721TokenReceiver tokenReceiver = ERC721TokenReceiver(_to);
 bytes4 returnValue = tokenReceiver.onERC721Received(_from, _tokenId,
data);
 require (returnValue ==
bytes4(keccak256("onERC721Received(address,uint256,bytes)")));
 }
 }
 function transferFrom(
 address _from,
 address _to,
 uint256 _tokenId
 ) external payable noHigherAccess(_to) {
 require (
 msg.sender == ipcToOwner[_tokenId] || // IPC owner
 msg.sender == ipcToMarketInfo[_tokenId].approvalAddress || // Approved address
 ownerToOperator[ipcToOwner[_tokenId]][msg.sender] == true // Approved operator
 );
 require (_tokenId != 0 && _tokenId <= totalIpcs);
 require (_from == ipcToOwner[_tokenId]);
 require (_to != 0);
 if (msg.sender == ipcToMarketInfo[_tokenId].approvalAddress) {
 require (_to == msg.sender);
 }
 _transferOwnership(_to, _from, _tokenId);
 }
 function approve(address _to, uint256 _tokenId) external payable {
 require (_tokenId <= totalIpcs && msg.sender == ipcToOwner[_tokenId]);
 ipcToMarketInfo[_tokenId].approvalAddress = _to;
 emit Approval(msg.sender, _to, _tokenId); // send the Approval event
 }
 function setApprovalForAll(address _operator, bool _approved) external {
 ownerToOperator[msg.sender][_operator] = _approved;
 emit ApprovalForAll(msg.sender, _operator, _approved); // send the ApprovalForAll event
 }
 function getApproved(uint256 _tokenId) external view returns (address) {
 require(_tokenId != 0 && _tokenId <= totalIpcs);
 return ipcToMarketInfo[_tokenId].approvalAddress;
 }
 function isApprovedForAll(address _owner, address _operator) external view returns
(bool) {
 return ownerToOperator[_owner][_operator];
 }
 function _transferOwnership(address _to, address _from, uint256 _tokenId) internal
{
 ownerIpcCount[_from]--; // remove IPC from seller's list of owned
 ipcToOwner[_tokenId] = _to; // change owner to buyer
 ipcToMarketInfo[_tokenId].beneficiaryAddress = 0; // remove any beneficiary
 if(ipcToMarketInfo[_tokenId].approvalAddress != 0) {
 emit Approval(msg.sender, 0, _tokenId);
 ipcToMarketInfo[_tokenId].approvalAddress = 0; // remove any pending approval
 }
 ownerIpcCount[_to]++; // add IPC to buyer's list of owned
 emit Transfer(_from, _to, _tokenId); // send the Transfer event
 }
 function _isContract(address addr) private view returns (bool) {
 uint size;
 assembly { size := extcodesize(addr) }
 return size > 0;
 }
}
//------------------------------------------------------------------------------
/// @title IPC Modification
/// @dev Handles modification of IPC names and DNA
//------------------------------------------------------------------------------
contract IpcModification is IpcMarketplace {
 /// @dev Emits whenever the name of an IPC is changed. Emits on IPC creation.

 event NameChanged(uint indexed _tokenId, string _to);
 uint public priceToModifyDna = 100;
 uint public priceToChangeName = 100;
 uint public dnaModificationLevelRequirement = 1000000;
 uint public nameModificationLevelRequirement = 1;
 modifier levelRequirement(uint _req, uint _ipcId) {
 require(Ipcs[_ipcId - 1].experience >= _req);
 _;
 }
 function changeDnaModificationLevelRequirement(uint _newReq) external
onlyExecOrHigher {
 dnaModificationLevelRequirement = _newReq;
 }
 function changeNameModificationLevelRequirement(uint _newReq) external
onlyExecOrHigher {
 nameModificationLevelRequirement = _newReq;
 }
 function changePriceToModifyDna(uint _newPrice) public onlyExecOrHigher {
 priceToModifyDna = _newPrice;
 }
 /// @notice Changes the name of an IPC
 /// @dev Throws unless msg.sender is the IPC's owner or an authorized administrator.
 /// Throws if msg.value is too low. Throws if _newName is longer than 32 bytes.
 /// Throws if IPC's experience is too low. Emits the NameChanged event.
 /// @param _ipcId The IPC Identifier for the IPC whose name will be changed.
 /// @param _newName Set the IPC's name to this string.
 function changeIpcName(
 uint _ipcId,
 string _newName
 ) public payable
 noReentrancy
 onlyOwnerOrAdmin(priceToChangeName, _ipcId)
 levelRequirement(nameModificationLevelRequirement, _ipcId)
 {
 require(bytes(_newName).length <= 32);

 uint index = _ipcId - 1;
 Ipcs[index].name = _newName;
 emit NameChanged(_ipcId, _newName);
 if (msg.sender == ipcToOwner[_ipcId]) {
 uint price = _convertCentsToWei(priceToChangeName);
 msg.sender.transfer(msg.value - price);
 ipcCashier.transfer(price);
 }
 }
 /// @notice Changes a specific byte of an IPC's dna by an amount. The price
 /// scales with modification amount.
 /// @dev Throws unless msg.sender is the IPC's owner or an authorized administrator.
 /// Throws if msg.value is too low. Throws if _byteToModify is greater than 31.
 /// Throws unless _ipcId is a valid IPC. Throws if modifying the _byteToModify by
 /// _modifyAmount overflows or underflows the byte value. Emits the DnaModified event.
 /// @param _ipcId The IPC Identifier for the IPC whose DNA will be modified
 /// @param _byteToModify The index of the byte to modify. Must be less than 32
 /// @param _modifyAmount The amount by which to increase or decrease the DNA byte value
 function modifyDna(
 uint _ipcId,
 uint _byteToModify,
 int _modifyAmount
 ) public payable
 noReentrancy
 levelRequirement(dnaModificationLevelRequirement, _ipcId)
 {
 // check enough money was sent
 uint costInWei;
 if(_modifyAmount < 0) {
 costInWei = _convertCentsToWei(priceToModifyDna * uint(_modifyAmount *
-1));
 require (
 _checkIfAdmin(msg.sender) ||
 (msg.sender == ipcToOwner[_ipcId] && msg.value >= costInWei)
 );
 } else {
 costInWei = _convertCentsToWei(priceToModifyDna * uint(_modifyAmount));
 require (

 _checkIfAdmin(msg.sender) ||
 (msg.sender == ipcToOwner[_ipcId] && msg.value >= costInWei)
 );
 }
 Ipc storage myIpc = Ipcs[_ipcId - 1];
 // requirements
 require (_ipcId < totalIpcs && myIpc.timeOfBirth != 0); // require valid IPC
 require (_byteToModify < 32); // require valid byte index (0-31)
 // calculate new dna value
 require (int(myIpc.dna[_byteToModify]) + _modifyAmount < 256 &&
 int(myIpc.dna[_byteToModify]) + _modifyAmount >= 0);
 int newDnaValue = int(myIpc.dna[_byteToModify]) + _modifyAmount;
 // construct an array of bytes as new dna
 bytes memory newDna = new bytes(32);
 for (uint i = 0; i < 32; ++i) {
 if (i == _byteToModify) {
 newDna[i] = byte(newDnaValue);
 } else {
 newDna[i] = myIpc.dna[i];
 }
 }
 // convert the array of bytes into a fixed-size bytes32 array
 bytes32 tempDnaBytes32;
 assembly {
 tempDnaBytes32 := mload(add(newDna, 32))
 }
 // set ipc dna to modified dna value
 myIpc.dna = tempDnaBytes32;
 // send event
 emit DnaModified(_ipcId, tempDnaBytes32);
 // send money
 if (msg.sender == ipcToOwner[_ipcId]) {
 msg.sender.transfer(msg.value - costInWei);
 ipcCashier.transfer(costInWei);
 }
 }

}
//------------------------------------------------------------------------------
/// @title IPC Experience
/// @dev Defines developer functions: experience creation, purchasing of XP, and
/// functions to grant XP to IPCs.
//------------------------------------------------------------------------------
contract IpcExperience is IpcModification {
 /// @dev This emits any time an IPC is gifted an XP by a developer
 event ExperienceEarned(uint indexed tokenId, address indexed developer, uint
indexed xpId);
 struct Developer {
 uint32 experienceCount;
 uint32 xpBalance;
 string name;
 }
 // contains information about a specific achievable experience
 struct Experience {
 address developer;
 string description;
 }
 // stores the developer info
 mapping (address => Developer) addressToDeveloper;
 // stores whether an IPC has been granted xp for a specific experience
 mapping (uint => mapping(uint => bool)) public ipcIdToExperience;
 // array of all experiences
 Experience[] public experiences;
 // pricing data
 uint xpPriceInCents = 1;
 function changeXpPrice(uint _newAmount) public onlyExecOrHigher {
 xpPriceInCents = _newAmount;
 }
 function setDeveloperName(address _address, string _name) external
onlyAdminOrHigher {
 require (_address != 0 && ipcDeveloper[_address]);

 addressToDeveloper[_address].name = _name;
 }
 //--------------------------------------------------------------------------
 // DEVELOPER FUNCTIONS
 //--------------------------------------------------------------------------
 /// @notice Grants xp to ipc
 /// @dev Throws if developer XP balance is 0. Throws if developer not
 /// the experience's owner. Throws if the IPC is not substantiated. Throws
 /// if IPC already earned the experience. Emits ExperienceEarned event.
 /// @param _ipcId The IPC Identifier for the IPC receiving the XP
 /// @param _xpId The XP Identifier for the experience given
 function grantXpToIpc(uint _ipcId, uint _xpId) public onlyDeveloper {
 Ipc storage ipc = Ipcs[_ipcId - 1];
 require (
 addressToDeveloper[msg.sender].xpBalance > 0 &&
 experiences[_xpId].developer == msg.sender &&
 ipc.timeOfBirth != 0 &&
 ipcIdToExperience[_ipcId][_xpId] == false
 );
 ipcIdToExperience[_ipcId][_xpId] = true;
 ipc.experience++;
 addressToDeveloper[msg.sender].xpBalance--;
 emit ExperienceEarned(_ipcId, msg.sender, _xpId);
 }
 /// @notice Grants XP to multiple IPCs. Costs significantly less gas than one-by-one.
 /// @dev Throws if developer's XP balance is too low to complete the operation.
 /// Throws if arrays are not equal in length. Checks each IPC against each experience.
 /// If valid, grants the XP. If not, continues to the next IPC and XP.
 /// It is up to the caller to make sure the IPC and XP arrays align correctly.
 /// @param _ipcIdArray An array of IPC Identifiers for the IPCs to receive XP
 /// @param _xpIdArray An array of XP to grant to IPCs.
 function grantBulkXp (uint[] _ipcIdArray, uint[] _xpIdArray) public onlyDeveloper
{
 require(addressToDeveloper[msg.sender].xpBalance >= _ipcIdArray.length &&
 _ipcIdArray.length == _xpIdArray.length);
 for (uint i = 0; i < _ipcIdArray.length; ++i) {
 if (
 addressToDeveloper[msg.sender].xpBalance > 0 &&

 experiences[_xpIdArray[i]].developer == msg.sender &&
 Ipcs[_ipcIdArray[i]].timeOfBirth != 0 &&
 ipcIdToExperience[_ipcIdArray[i]][_xpIdArray[i]] == false
 ) {
 ipcIdToExperience[_ipcIdArray[i]][_xpIdArray[i]] = true;
 Ipcs[_ipcIdArray[i] - 1].experience++;
 emit ExperienceEarned(_ipcIdArray[i], msg.sender, _xpIdArray[i]);
 }
 }
 addressToDeveloper[msg.sender].xpBalance -= uint32(_ipcIdArray.length);
 }
 /// @notice Developer-only function to purchase Experience Points
 /// @dev Sends the developer however many experience points his msg.value
 /// can afford. Sends the remainder back to the buyer. Throws if sender is
 /// not a developer.
 function buyXp() external payable onlyDeveloper noReentrancy {
 uint xpPriceInWei = _convertCentsToWei(xpPriceInCents);
 uint xpBought = msg.value / xpPriceInWei;
 addressToDeveloper[msg.sender].xpBalance += uint32(xpBought);
 ipcCashier.transfer(xpPriceInWei * xpBought);
 msg.sender.transfer(msg.value - (xpPriceInWei * xpBought));
 }
 /// @notice Registers a new experience into the idToExperience mapping
 /// @dev Throws if the sender is not a developer. The longer the _description
 /// the more gas this function costs. If the description is very long
 /// it is recommended to store a metadata uri conforming to RFC3986 syntax
 /// described here https://tools.ietf.org/html/rfc3986
 /// @param _description String describing the experience
 function registerNewExperience(string _description) external onlyDeveloper
returns(uint) {
 uint experienceId = experiences.push(Experience (msg.sender, _description)) -
1;
 addressToDeveloper[msg.sender].experienceCount++;
 return experienceId;
 }
 /// @notice Invalidates an existing Experience
 /// @dev Sets the experience's developer to the 0 address, which makes the
 /// experience impossible to access. If the experience needs to be reactivated
 /// it needs to be created as a new experience.

 /// @param _xpId The Experience Identifier for the Experience to remove
 function removeExperience(uint _xpId) external onlyDeveloper {
 require (experiences[_xpId].developer == msg.sender);
 addressToDeveloper[msg.sender].experienceCount--;
 experiences[_xpId].developer = 0;
 }
 /// @notice Developer-only getter that returns XP price in cents
 /// @dev Throws if msg.sender is not a developer
 function getXpPrice() external view onlyDeveloper returns (uint) {
 return xpPriceInCents;
 }
 /// @notice Developer-only getter that returns their XP balance
 /// @dev Throws if msg.sender is not a developer
 function getXpBalance() external view onlyDeveloper returns (uint) {
 return addressToDeveloper[msg.sender].xpBalance;
 }
 /// @notice Public getter that shows all the Experiences owned by a developer
 /// @dev Throws if the developer owns no Experiences.
 /// @param _developer The address to search for owned Experiences.
 /// @return An array of Experience Identifiers owned by _developer
 function experiencesOfDeveloper(address _developer) external view returns (uint[])
{
 uint counter = addressToDeveloper[_developer].experienceCount;
 require(counter > 0);
 uint[] memory result = new uint[](counter);
 for (uint i = 0; i < Ipcs.length; i++) {
 result[counter] = i;
 }
 return result;
 }
}
//------------------------------------------------------------------------------
// IPC CORE
// - provides the IPC interface for which external contracts or dapps can read IPC data
//------------------------------------------------------------------------------
contract IpcCore is IpcExperience, ERC721Metadata {

 address public mostCurrentIpcAddress = address(this);
 mapping (bytes4 => bool) supportedInterfaces;
 string ipcUrl;
 // Constructor - called once and only once when contract is created
 function IpcCore() public {
 ipcGod = msg.sender;
 ipcCap = trancheSize;
 supportedInterfaces[0x01ffc9a7] = true; // ERC-165
 supportedInterfaces[0x6466353c] = true; // ERC-721
 supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
 supportedInterfaces[0xf0b9e5ba] = true; // ERC721TokenReceiver
 supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
 ipcUrl = "https://www.immortalplayercharacters.com/ipc/";
 //priceConverter = MarketPrice(0x2138FfE292fd0953f7fe2569111246E4DE9ff1DC);
// main
 priceConverter = MarketPrice(0x97d63Fe27cA359422C10b25206346B9e24A676Ca); //testnet
 }
 function updateIpcContract(address _newAddress) external onlyExecOrHigher {
 mostCurrentIpcAddress = _newAddress;
 }
 function updateIpcUrl(string _newUrl) external onlyExecOrHigher {
 ipcUrl = _newUrl;
 }
 function addSupportedInterface(bytes4 _newInterfaceId) external onlyExecOrHigher {
 supportedInterfaces[_newInterfaceId] = true;
 }
 function removeSupportedInterface(bytes4 _interfaceId) external onlyExecOrHigher {
 supportedInterfaces[_interfaceId] = false;
 }
 /// @notice Returns all ipc stats to the caller.
 /// @dev note: If the caller was an external contract, Ipc.name will be unreadable.
 /// @param _ipcId The IPC Identifier for the IPC to be read
 /// @return name, attributeSeed, dna, experience, and timeOfBirth of an IPC
 function getIpc(uint _ipcId) external view returns (
 string name,
 bytes32 attributeSeed,
 bytes32 dna,
 uint128 experience,
 uint128 timeOfBirth
 ) {
 Ipc storage ipc = Ipcs[_ipcId - 1];
 name = ipc.name;
 experience = ipc.experience;
 attributeSeed = ipc.attributeSeed;
 dna = ipc.dna;
 timeOfBirth = ipc.timeOfBirth;
 }
 /// @notice Converts name to bytes32 for external contract use.
 /// @dev returns a bytes32 containing the IPCs name followed by 0s. If the
 /// IPCs name ends with 0s they will be indistinguishable from the 0s added
 /// by this method.
 /// @param _ipcId The IPC Identifier for the IPC whose name is being looked up
 /// @return byte32 containing the IPCs name followed by 0s
 function getIpcName(uint _ipcId) external view returns (bytes32 result) {
 bytes memory nameBytes = new bytes(32);
 Ipc storage ipc = Ipcs[_ipcId - 1];
 if (bytes(ipc.name).length == 0) {
 return 0x0;
 }
 for (uint i = 0; i < bytes(ipc.name).length; ++i) {
 nameBytes[i] = bytes(ipc.name)[i];
 }
 assembly {
 result := mload(add(nameBytes, 32))
 }
 }
 /// @notice Check how much wei an existing IPC costs
 /// @dev updates roughly once every ten minutes
 /// @param _ipcId The IPC Identifier for the IPC price to look up

 /// @return The amount the IPC costs in wei
 function getIpcPriceInWei(uint _ipcId) external view returns (uint) {
 return _convertCentsToWei(ipcToMarketInfo[_ipcId].sellPrice);
 }
 // ERC721Metadata functions
 function name() external pure returns (string) {
 return "ImmortalPlayerCharacter";
 }
 function symbol() external pure returns (string) {
 return "IPC";
 }
 // returns url + IPC as a string
 function tokenURI(uint _tokenId) external view returns (string) {
 uint ipcId = _tokenId;
 require (_tokenId > 0 && _tokenId <= totalIpcs);
 bytes32 ipcIdBytes32;
 while(_tokenId > 0) {
 ipcIdBytes32 = bytes32(uint(ipcIdBytes32) / (2 ** 8));
 ipcIdBytes32 |= bytes32(((_tokenId % 10) + 48) * 2 ** (8 * 31));
 ipcId /= 10;
 }
 bytes memory bytesString = new bytes(32);
 for (uint i = 0; i < 32; ++i) {
 byte char = byte(bytes32(uint(ipcIdBytes32) * 2 **(8 * i)));
 if (char != 0) {
 bytesString[i] = char;
 }
 }
 bytes memory newStringBytes = new bytes(bytes(ipcUrl).length +
bytesString.length);
 uint counter = 0;
 for (i = 0; i < bytes(ipcUrl).length; i++) {
 newStringBytes[counter++] = bytes(ipcUrl)[i];
 }
 for (i = 0; i < bytesString.length; i++) {
 newStringBytes[counter++] = bytesString[i];

 }
 return string(newStringBytes);
 }
 // ERC165 function
 function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
 return supportedInterfaces[_interfaceId];
 }
}