pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MultiSender is AccessControl {

    using Address for address;

    bytes32 public constant LORD_ROLE = keccak256("LORD_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // pool token - admin map
    mapping(address => address) public stakingAdmins;

    modifier onlyStakingAdmin(address admin, address token) {
        require(hasRole(ADMIN_ROLE, admin), "admin role not granted");
        require(stakingAdmins[token] == admin, "unauthorized admin");
        _;
    }

    modifier onlyTokenContract (address token) {
        require(token.isContract(), "not the token contract");
        _;
    }

    constructor() {
        // set up the lord role to the deployer
        _setupRole(LORD_ROLE, msg.sender);
        _setRoleAdmin(OWNER_ROLE, LORD_ROLE);
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
    }

    function addOwner(address _newOwner) public onlyRole(LORD_ROLE) {
        grantRole(OWNER_ROLE, _newOwner);
    }

    function removeOwner(address _oldOwner) public onlyRole(LORD_ROLE) {
        revokeRole(OWNER_ROLE, _oldOwner);
    }

    function addAdmin(address _newAdmin, address token) public onlyRole(OWNER_ROLE) onlyTokenContract(token) {
        grantRole(ADMIN_ROLE, _newAdmin);
        stakingAdmins[token] = _newAdmin;
    }

    function removeAdmin(address _oldAdmin, address token) public onlyRole(OWNER_ROLE) onlyTokenContract(token) {
        revokeRole(ADMIN_ROLE, _oldAdmin);
        delete stakingAdmins[token];
    }

    function changeAdmin(address _newAdmin,address _oldAdmin, address token) external onlyRole(OWNER_ROLE) onlyTokenContract(token) {
        // first revoke the old admin role
        removeAdmin(_oldAdmin, token);
        addAdmin(_newAdmin, token);
    }

    // multi distribute ETH
    function multiSend(address[] memory recipients, uint256[] memory values) external payable onlyRole(OWNER_ROLE) {
        for(uint256 i = 0; i < recipients.length; ++i) {
            address payable _recipient = payable(recipients[i]);
            (bool success,) = _recipient.call{value : values[i]}("");
            require(success, "failed to transfer ether");
        }
    }
    
    // only staking pool admin can distribute tokens
    function multiSendToken(address _token, address[] memory recipients, uint256[] memory values) external onlyStakingAdmin(msg.sender, _token) {
        IERC20 token = IERC20(_token);
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function withdraw(uint256 amount, address payable to) external onlyRole(OWNER_ROLE) {
        (bool success,) = to.call{value : amount}("");
        require(success, "ether transfer failed");
    }

    // owner can withdraw tokens, but only to the token pool's admin address
    function withdrawToken (address _token, uint256 amount, address to) external onlyRole(OWNER_ROLE){
        require(IERC20(_token).transfer(to, amount));
    }

    function withdrawTokenAsAdmin (address _token, uint256 amount) external onlyStakingAdmin(msg.sender, _token) {
        require(IERC20(_token).transfer(msg.sender, amount));
    }

    receive () external payable {

    }
}