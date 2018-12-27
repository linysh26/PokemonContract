pragma solidity  ^0.5.0;


// interface for contracts conforming to ERC-721: NFT (Non-Fungible Tokens 非同质化代币)
// refering from cryptokitty
// 非同质化代币的特点：
// 在同一合约范围内，每一枚NFT拥有唯一的Token ID
// 一个Token ID只能被一个拥有者（Owner）或者钱包地址（Address）所拥有
// NFT最小单位为1且不可分割，拥有者或者地址可以拥有多个NFTs，结算时只计数量，拥有者和Token ID的对应关系另有列表记录
// 每一个NFT都会有一个复合地址来存储这个代币的元数据（Metadata），比如图片、名称等各种属性，这些元数据可被查看
// ERC-721标准的代币和ERC-20的代币有兼容的地方，故ERC-721标准代币可以显示在ERC-20标准的钱包中。
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
  	owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/// @title A facet of KittyCore that manages special access privileges.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See the KittyCore contract documentation to understand how the various contract facets are arranged.
contract PokemonAccessControl {
    // This facet controls access control for CryptoKitties. There are four roles managed here:
    //
    //     - The CEO: The CEO can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract. It is initially
    //         set to the address that created the smart contract in the KittyCore constructor.
    //
    //     - The CFO: The CFO can withdraw funds from KittyCore and its auction contracts.
    //
    //     - The COO: The COO can release gen0 kitties to auction, and mint promo cats.
    //
    // It should be noted that these roles are distinct without overlap in their access abilities, the
    // abilities listed for each role above are exhaustive. In particular, while the CEO can assign any
    // address to any role, the CEO address itself doesn't have the ability to act in those roles. This
    // restriction is intentional so that we aren't tempted to use the CEO address frequently out of
    // convenience. The less we use an address, the less likely it is that we somehow compromise the
    // account.

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}

contract PokemonBase is PokemonAccessControl{

	// NewPokemon event is fired whenever a new pokemon comes into existence 
	event PokemonAppear(uint pokemonId, string name, uint dna);
  	// Transfer event is fired whenever a existed pokemon is transfered from one to another
	event Transfer(address from, address to, uint256 tokenId);
	// Gotcha event is fired whenever trainer gotcha a pokemon
	event Gotcha(uint256 pokemonId, address by);

	// 神奇宝贝
	struct Pokemon{
		// pokemon's name
		string name;
		// define what kind of pokemon it is and whether it is a shiny one or not
		uint genes;
		// level of pokemon which determine wheather the pokemon can evolve or not
		uint32 level;
		// gotcha time
		uint64 gotchaTime;
	}

	Pokemon[] public pokemons;

	// the mapping from pokemon's id to its trainner
	mapping(uint => address) public pokemonToTrainer;
	// the mapping from trainner to number of pokemon possessed
	mapping(address => uint) public trainerToPokemonCount;
	// the pokemon id to address approved to call transferFrom()
	mapping(uint => address) public pokemonIdToApproved;


	// define clock time when a wild pokemon appear
	// SaleClockAuction public saleAuction;
	AppearClockAuction appearAuction;

	function _createPokemon() internal returns (uint256){

		uint256 _genes = uint256(keccak256("TEST"));
		Pokemon memory _pm = Pokemon({
			name: "",
			genes: _genes,
			level: 5,
			gotchaTime: uint64(now)
		});
		uint256 newPokemonId = pokemons.push(_pm) - 1;
		pokemonToTrainer[newPokemonId] = address(0);
		// emit new pokemon appear event
		emit PokemonAppear(newPokemonId, _pm.name, _genes);

		return newPokemonId;
	}

    function _transfer(address _from, address _to, uint256 _tokenId) internal{

        trainerToPokemonCount[_to]++;
        pokemonToTrainer[_tokenId] = _to; 

        
        if(_from != address(0)){
            trainerToPokemonCount[_from]--;
        }

        // fire the transfer event
        emit Transfer(_from, _to, _tokenId);
    }

    function _gotcha(uint256 _pokemonId, address _by) internal{
    	require(_by != address(0));
    	trainerToPokemonCount[_by]++;
    	pokemonToTrainer[_pokemonId] = _by;
    	pokemons[_pokemonId].gotchaTime = uint64(now);
    	// fire the gotcha event
    	emit Gotcha(_pokemonId, _by);
    }
}

contract PokemonOwnership is PokemonBase, ERC721{


	/// name and symbol of a non-fungiable token defined in ERC721
	string public constant name = "Pokemons";
	string public constant symbol = "PM";

	// The contract that will return pokemon metadata
    ERC721Metadata public erc721Metadata;

	bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256,string)'));

	function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address is the current owner of a particular Kitty.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId kitten id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return pokemonToTrainer[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Kitty.
    /// @param _claimant the address we are confirming kitten is approved for.
    /// @param _tokenId kitten id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return pokemonIdToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting Kitties on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        pokemonIdToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of Kitties owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return trainerToPokemonCount[_owner];
    }

    function gotcha(
    	uint256 _tokenId,
    	address _by
    )
    	external
    	whenNotPaused
    {
    	// only trainer can gotcha a pokemon!
    	require(_by != address(0));

    	// only wild pokemon can be gotcha!
    	require(pokemonToTrainer[_tokenId] == address(0));

    	// Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of pokemon
        // through the allow + transferFrom flow.
    	require(_by != address(appearAuction));

    	// you can not gotcha your pokemon again
    	require(_owns(msg.sender, _tokenId));

    	_gotcha(_tokenId, _by);
    }

    /// @notice Transfers a Kitty to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  CryptoKitties specifically) or your Kitty may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Kitty to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any kitties (except very briefly
        // after a gen0 cat is created and before it goes on auction).
        require(_to != address(this));
        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of pokemon
        // through the allow + transferFrom flow.
        require(_to != address(appearAuction));

        // You can only send your own cat.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific Kitty via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Kitty that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a Kitty owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Kitty to be transfered.
    /// @param _to The address that should take ownership of the Kitty. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Kitty to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any kitties (except very briefly
        // after a gen0 cat is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of Kitties currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return pokemons.length - 1;
    }

    /// @notice Returns the address currently assigned ownership of a given Kitty.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = pokemonToTrainer[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns a list of all Kitty IDs assigned to an address.
    /// @param _owner The owner whose Kitties we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Kitty array looking for cats belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
		uint256[] memory result;
        if (tokenCount == 0) {
        	result = new uint256[](0);
            // Return an empty array
            return result;
        } else {
            result = new uint256[](tokenCount);
            uint256 totalPokemons = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all cats have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 pokemonId;

            for (pokemonId = 1; pokemonId <= totalPokemons; pokemonId++) {
                if (pokemonToTrainer[pokemonId] == _owner) {
                    result[resultIndex] = pokemonId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @dev Adapted from memcpy() by @arachnid (Nick Johnson <arachnid@notdot.net>)
    ///  This method is licenced under the Apache License.
    ///  Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
    function _memcpy(uint _dest, uint _src, uint _len) private view {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

    /// @dev Adapted from toString(slice) by @arachnid (Nick Johnson <arachnid@notdot.net>)
    ///  This method is licenced under the Apache License.
    ///  Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
    function _toString(bytes32[4] memory _rawBytes, uint256 _stringLength) private view returns (string memory) {
        string memory outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

    /// @notice Returns a URI pointing to a metadata package for this token conforming to
    ///  ERC-721 (https://github.com/ethereum/EIPs/issues/721)
    /// @param _tokenId The ID number of the Kitty whose metadata should be returned.
    function tokenMetadata(uint256 _tokenId, string calldata _preferredTransport) external view returns (string memory infoUrl) {
        require(address(erc721Metadata) != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}
/// @title Contract define when and how a pokemon evolve
/// @author 星空 (https://github.com/linysh26)
/// @dev 
contract PokemonEvolution is PokemonOwnership{
	/// @dev Define event whenever any pokemon is going on revolution
	/// @param tokenId The id of pokemon
	/// @param owner The address of owner
	event Evolution(uint256 tokenId, address owner, uint256 genes, uint256 fee);

	/// @notice The fee cost everytime function evolve is called by user
	///  can be set by cfo when gas changes
	uint256 public evolveFee = 2 finney;

	// experience of the pokemon
	uint256 public experience;

	/// @dev Check if the pokemon's lv has reached the LV
	/// it can evolve
	function _isReadyToEvolve(Pokemon memory _pm, uint256 _lv) internal view returns (bool){
		return _pm.level == _lv;
	}
	/// @dev Check if the pokemon has reached the level to evolve
	/// @param _pm The pokemonId we are interested in
	/// @param _lv The level this type of pokemon can evolve
	function isReadyToEvolve(uint256 _pokemonId, uint256 _lv)
		public
		view
		returns (bool)
	{
		require(_pokemonId > 0);
		Pokemon storage pm = pokemons[_pokemonId];
		return _isReadyToEvolve(pm, _lv);
	}

	function _evolve(uint256 pokemonId) internal{
		
		Pokemon storage pm = pokemons[pokemonId];

		// emit the evolution event
		emit Evolution(
			pokemonId,
			pokemonToTrainer[pokemonId],
			pm.genes,
			evolveFee
			);
	}
	/// @notice You are going to evolve a pokemon you own which is evolvable
	/// @param pokemonId The pokemon you are going to evolve
	function evolve(uint256 pokemonId, uint256 lvToEvolve)
		external
		payable
		whenNotPaused
	{
		// check for payment
		require(msg.value >= evolveFee);

		// check for ownership
		require(_owns(msg.sender, pokemonId));

		require(isReadyToEvolve(pokemonId, lvToEvolve));

		_evolve(pokemonId);
	}
}

contract PokemonAuction is PokemonEvolution{

	function setAppearAuctionAddress(address _address) external onlyCEO{
		AppearClockAuction candidateContract = AppearClockAuction(_address);

		// note: verify that a contract is what we expect
		require(candidateContract.isAppearClockAuction());

		// Set the new contract address
		appearAuction = candidateContract;
	}

	function createAppearAuction(
		uint256 _pokemonId,
		uint256 _startingDifficulty,
		uint256 _duration
	)
		external
		whenNotPaused
	{
		_approve(_pokemonId, address(appearAuction));

		appearAuction.createAuction(
			_pokemonId,
			_startingDifficulty,
			_duration
		);
	}
}

/// @dev 
contract PokemonMinting is PokemonAuction{
	// Limits the number of pokemons appear waiting for gotcha
	uint256 public constant  APPEAR_LIMIT = 1000;

	// Default duration
	uint256 public APPEAR_DURATION = 1 days;

	// Counts the number of pokemons the contract owner has gotcha
	uint256 public appearCount;

	function appear(uint256 _genes) external onlyCOO{
		require(appearCount < APPEAR_LIMIT);

		uint256 pokemonId = _createPokemon();
		_approve(pokemonId, address(appearAuction));

		appearAuction.createAuction(
			pokemonId,
			1000,
			APPEAR_DURATION
			);
	}

}

contract PokemonCore is PokemonMinting{


	constructor()public{
		// Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;
	}

	function getPokemon(uint256 _id)
		external
		view
		returns(
			uint256 lv,
			uint256 genes)
	{
		Pokemon storage _pm = pokemons[_id];
		lv = uint256(_pm.level);
		genes = uint256(_pm.genes);
	}

	function unpause() public onlyCEO whenPaused {
        require(address(appearAuction) != address(0));
        // Actually unpause the contract.
        super.unpause();
    }

}

// generate metadata to pokemon
contract ERC721Metadata {
    /// @dev Given a token Id, returns a byte array that is supposed to be converted into string.
    function getMetadata(uint256 _tokenId, string memory) public view returns (bytes32[4] memory buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}

contract ClockAuctionBase{

    // Represents an auction on an NFT
    struct Auction{
    	//
    	uint256 tokenId;
        // difficulty to gotcha the pokemon at the beginning of auction
        uint128 startingDifficulty;
        // price (in wei) at end of auction
        uint128 currentDifficulty;
        // duration (in seconds) of auction
        uint64 duration;
        // time when auction started
        // NOTE: 0 if this auction has been concluded (如果拍卖结束，则结束拍卖计时)
        uint64 startedAt;
    }

    // Reference to contract tracking NFT ownership
    ERC721 public nonFungibleContract;

    uint256 public ownerCut;

    // mapping from tokenId to its auction
    mapping (uint256 => Auction) tokenIdToAuction;

    // auction related event
    // fired whenever an auction created
    event AuctionCreated (uint256 tokenId, uint256 startingDifficulty, uint256 currentDifficulty, uint256 duration);
    // fired whenever an auction succeeds
    event AuctionSuccessful(uint256 tokenId, address winner);
    // fired whenever an auction
    event AuctionCancelled(uint256 tokenId);

    // return true if the claimant owns the token
    function _owns(address _claimant, uint _tokenId) internal view returns(bool){
        return (nonFungibleContract.ownerOf(_tokenId)) == _claimant;
    }

    function _escrow(address _owner, uint256 _tokenId) internal{
        nonFungibleContract.transferFrom(_owner, address(this), _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
      
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction memory _auction) internal{

        // all duration have at least one minute
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        // fire AuctionCreated event
        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingDifficulty),
            uint256(_auction.currentDifficulty),
            uint256(_auction.duration)
        );
    }

    // cancels an auction unconditionally
    function _cancelAuction(uint256 _tokenId) internal{
      // remove the auction corresponding to the token
      _removeAuction(_tokenId);
      // 
    }

    function _removeAuction(uint256 _tokenId)internal {
      delete tokenIdToAuction[_tokenId];
    }

    // check if the NTF is on auction
    function _isOnAuction(Auction storage _auction) internal view returns (bool){
      return (_auction.startedAt > 0);
    }

    // decrease difficulty according to trainer's pokeball
    function _decreaseDifficulty(
    	uint256 tokenId,
    	address by,
    	uint128 decrement
    	)
    internal
    returns (uint128)
    {
    	Auction memory _auction = tokenIdToAuction[tokenId];
    	_auction.currentDifficulty -= decrement;
    	if(_auction.currentDifficulty <= 0){
    		
    		emit AuctionSuccessful(tokenId, by);
    		return 0;
    	}
    	else{
    		return _auction.currentDifficulty;
    	}
    }

    function _currentDifficulty(Auction memory _auction) internal view returns (uint256){
    	return _auction.currentDifficulty;
    }
    function _computeCut(uint _price) internal view returns (uint256){

      return _price * ownerCut / 10000;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

contract ClockAuction is Pausable, ClockAuctionBase{

    // signature for ERC-721
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);
	/// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    constructor(address _ntfAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_ntfAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }


    /// @dev Creates and begins a new auction.
    function createAuction(
        uint256 _tokenId,
        uint256 _startingDifficulty,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        Auction memory auction = Auction(
        	uint256(_tokenId),
            uint128(_startingDifficulty),
            uint128(_startingDifficulty),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        uint256 startingDifficulty,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.startingDifficulty,
            auction.duration,
            auction.startedAt
        );
    }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentDifficulty(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentDifficulty(auction);
    }
}

/// @title Clock auction modified for appear of pokemon
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract AppearClockAuction is ClockAuction {

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSaleAuctionAddress() call.
    bool public isAppearClockAuction = true;

    // Delegate constructor
    constructor(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

    /// @dev Creates and begins a new auction.
    function createAuction(
        uint256 _tokenId,
        uint256 _startingDifficulty,
        uint256 _duration
    )
        external
    {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_duration == uint256(uint64(_duration)));
        Auction memory auction = Auction(
        	uint256(_tokenId),
            uint128(_startingDifficulty),
            uint128(_startingDifficulty),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Decrease difficulty of catching the exists pokemon
    /// when hit by a pokeball from trainer
    /// @param tokenId The pokemon trainer going to gotcha
    /// @param from The trainer
    /// @param decrement The hit point depends on the quality of
    /// the pokeball from the trainer
    function decreaseDifficulty(
    	uint256 tokenId,
    	address by,
    	uint128 decrement
    )
    	external
    	returns (bool)
    {
    	return _decreaseDifficulty(tokenId, by, decrement) == 0;
    }

}
