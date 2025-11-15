// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:pinenacl/tweetnacl.dart';
import 'xdr/xdr_transaction.dart';
import 'operation.dart';
import 'muxed_account.dart';
import 'util.dart';
import 'assets.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_contract.dart';
import 'xdr/xdr_type.dart';
import 'soroban/soroban_auth.dart';

/// Base class for Soroban smart contract host functions.
///
/// HostFunction defines the different types of Soroban contract operations that
/// can be invoked on the Stellar network. Soroban smart contracts run in a WASM
/// runtime and interact with the ledger through host functions.
///
/// Host Function Types:
/// - **InvokeContract**: Call a deployed smart contract function
/// - **CreateContract**: Deploy a new WASM contract instance
/// - **UploadContractWasm**: Upload WASM bytecode to the network
/// - **DeploySAC**: Deploy Stellar Asset Contract (SAC) for an asset
///
/// Soroban contracts enable:
/// - Complex business logic beyond classic Stellar operations
/// - Multi-party agreements and escrow mechanisms
/// - Programmable assets with custom behavior
/// - Cross-contract calls and composability
/// - Integration with external data via oracles
///
/// See also:
/// - [InvokeHostFunctionOperation] to execute host functions
/// - [RestoreFootprintOperation] to restore archived contract state
/// - [ExtendFootprintTTLOperation] to extend contract state TTL
abstract class HostFunction {
  /// Creates a host function for Soroban smart contract operations.
  HostFunction();

  XdrHostFunction toXdr();

  factory HostFunction.fromXdr(XdrHostFunction xdr) {
    XdrHostFunctionType type = xdr.type;
    switch (type) {
      // Account effects
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM:
        if (xdr.wasm != null) {
          return UploadContractWasmHostFunction(xdr.wasm!.dataValue);
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT:
        if (xdr.invokeContract != null) {
          XdrInvokeContractArgs invokeArgs = xdr.invokeContract!;
          String contractID = invokeArgs.contractAddress.toStrKey();
          String functionName = invokeArgs.functionName;
          List<XdrSCVal> funcArgs = invokeArgs.args;
          return InvokeContractHostFunction(contractID, functionName,
              arguments: funcArgs);
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT:
        if (xdr.createContract != null) {
          if (xdr.createContract!.contractIDPreimage.type ==
              XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS) {
            if (xdr.createContract!.executable.type ==
                    XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM &&
                xdr.createContract!.executable.wasmHash != null) {
              String wasmId = Util.bytesToHex(
                  xdr.createContract!.executable.wasmHash!.hash);
              return CreateContractHostFunction(
                  Address.fromXdr(
                      xdr.createContract!.contractIDPreimage.address!),
                  wasmId,
                  salt: xdr.createContract!.contractIDPreimage.salt!);
            } else if (xdr.createContract!.executable.type ==
                XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET) {
              return DeploySACWithSourceAccountHostFunction(
                  Address.fromXdr(
                      xdr.createContract!.contractIDPreimage.address!),
                  salt: xdr.createContract!.contractIDPreimage.salt!);
            }
          } else if (xdr.createContract!.contractIDPreimage.type ==
                  XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET &&
              xdr.createContract!.executable.type ==
                  XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET) {
            return DeploySACWithAssetHostFunction(Asset.fromXdr(
                xdr.createContract!.contractIDPreimage.fromAsset!));
          }
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2:
        if (xdr.createContractV2 != null) {
          if (xdr.createContractV2!.contractIDPreimage.type ==
              XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS) {
            if (xdr.createContractV2!.executable.type ==
                XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM &&
                xdr.createContractV2!.executable.wasmHash != null) {
              String wasmId = Util.bytesToHex(
                  xdr.createContractV2!.executable.wasmHash!.hash);
              return CreateContractWithConstructorHostFunction(
                  Address.fromXdr(
                      xdr.createContractV2!.contractIDPreimage.address!),
                  wasmId, xdr.createContractV2!.constructorArgs,
                  salt: xdr.createContractV2!.contractIDPreimage.salt!);
            } else if (xdr.createContractV2!.executable.type ==
                XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET) {
              return DeploySACWithSourceAccountHostFunction(
                  Address.fromXdr(
                      xdr.createContractV2!.contractIDPreimage.address!),
                  salt: xdr.createContractV2!.contractIDPreimage.salt!);
            }
          } else if (xdr.createContractV2!.contractIDPreimage.type ==
              XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET &&
              xdr.createContractV2!.executable.type ==
                  XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET) {
            return DeploySACWithAssetHostFunction(Asset.fromXdr(
                xdr.createContractV2!.contractIDPreimage.fromAsset!));
          }
        }
        break;
    }
    throw UnimplementedError();
  }
}

/// Uploads WebAssembly (WASM) bytecode for smart contract deployment.
///
/// This host function uploads compiled contract code to the Stellar network,
/// making it available for deployment as contract instances. The WASM code
/// must be valid for the Soroban environment and is uploaded once, then
/// referenced by hash when creating contract instances.
///
/// WASM in Soroban:
/// - **WebAssembly**: Binary instruction format for smart contracts
/// - **Compilation**: Rust contracts compile to WASM bytecode
/// - **Storage**: WASM stored once, reused for multiple contract instances
/// - **Validation**: Network validates WASM before accepting upload
///
/// Upload Process:
/// 1. Compile contract source code to WASM
/// 2. Upload WASM via this host function
/// 3. Network returns WASM hash
/// 4. Use hash to create contract instances
///
/// Use Cases:
/// - Deploy new smart contract code
/// - Update contract implementations
/// - Share contract code across instances
/// - Separate code deployment from instantiation
///
/// Example - Upload Contract WASM:
/// ```dart
/// // Read compiled WASM file
/// var wasmBytes = File('contract.wasm').readAsBytesSync();
///
/// var uploadFunction = UploadContractWasmHostFunction(wasmBytes);
///
/// var uploadOp = InvokeHostFuncOpBuilder(uploadFunction)
///   .setSourceAccount(deployerAccountId)
///   .build();
///
/// // Include in transaction with appropriate footprint and fees
/// var transaction = TransactionBuilder(deployerAccount)
///   .addOperation(uploadOp)
///   .setSorobanData(footprint)
///   .build();
/// ```
///
/// Important Considerations:
/// - WASM must pass network validation
/// - Upload fees based on bytecode size
/// - WASM hash used for subsequent deployments
/// - Code is immutable once uploaded
/// - Consider WASM size optimization
///
/// See also:
/// - [CreateContractHostFunction] to deploy contract from WASM
/// - [InvokeHostFunctionOperation] to execute the upload
class UploadContractWasmHostFunction extends HostFunction {
  Uint8List _contractCode;

  /// The compiled WASM bytecode to upload.
  Uint8List get contractCode => this._contractCode;
  set contractCode(Uint8List value) => this._contractCode = value;

  /// Creates an UploadContractWasmHostFunction.
  ///
  /// Parameters:
  /// - [_contractCode]: Compiled WASM bytecode (raw binary format).
  UploadContractWasmHostFunction(this._contractCode);

  /// Converts this host function to its XDR representation.
  ///
  /// Returns: XDR host function for WASM upload.
  @override
  XdrHostFunction toXdr() {
    return XdrHostFunction.forUploadContractWasm(contractCode);
  }
}

/// Creates a new smart contract instance from uploaded WASM code.
///
/// This host function deploys a contract instance from previously uploaded
/// WASM bytecode. Each instance is uniquely identified by the combination of
/// deployer address, WASM hash, and salt. Multiple instances can be created
/// from the same WASM code, each maintaining independent state.
///
/// Contract Creation:
/// - **WASM Hash**: Reference to uploaded WASM bytecode
/// - **Deployer Address**: Account or contract creating the instance
/// - **Salt**: Random or chosen value ensuring unique contract ID
/// - **Contract ID**: Deterministically derived from address, salt, and network
///
/// Deployment Process:
/// 1. Upload WASM code (if not already uploaded)
/// 2. Create contract instance with this function
/// 3. Network assigns unique contract ID
/// 4. Contract ready for invocation
///
/// Use Cases:
/// - Deploy custom smart contracts
/// - Create multiple instances from same code
/// - Upgrade contracts by deploying new instances
/// - Factory pattern for contract creation
///
/// Example - Create Contract Instance:
/// ```dart
/// // After uploading WASM and getting wasmId
/// var deployerAddress = Address.forAccountId(deployerAccountId);
///
/// var createFunction = CreateContractHostFunction(
///   deployerAddress,
///   wasmId
/// );
///
/// var createOp = InvokeHostFuncOpBuilder(createFunction)
///   .setSourceAccount(deployerAccountId)
///   .build();
///
/// var transaction = TransactionBuilder(deployerAccount)
///   .addOperation(createOp)
///   .setSorobanData(footprint)
///   .build();
/// ```
///
/// Important Considerations:
/// - Requires previously uploaded WASM
/// - Each instance has independent state
/// - Contract ID is deterministic based on inputs
/// - Salt allows multiple instances from same deployer
/// - Consider gas costs for initialization
///
/// See also:
/// - [UploadContractWasmHostFunction] to upload WASM first
/// - [CreateContractWithConstructorHostFunction] for contracts with constructor
/// - [InvokeContractHostFunction] to call contract functions
class CreateContractHostFunction extends HostFunction {
  Address _address;

  /// The address of the deployer (account or contract).
  Address get address => this._address;
  set address(Address value) => this._address = value;

  String _wasmId;

  /// The hex-encoded hash of the uploaded WASM code.
  String get wasmId => this._wasmId;
  set wasmId(String value) => this._wasmId = value;

  late XdrUint256 _salt;

  /// Random salt for unique contract ID generation.
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  /// Creates a CreateContractHostFunction.
  ///
  /// Parameters:
  /// - [_address]: Deployer address (account or contract).
  /// - [_wasmId]: Hash of previously uploaded WASM code.
  /// - [salt]: Optional salt for contract ID (generated if not provided).
  CreateContractHostFunction(this._address, this._wasmId, {XdrUint256? salt}) {
    if (salt != null) {
      this._salt = salt;
    } else {
      this._salt = new XdrUint256(TweetNaCl.randombytes(32));
    }
  }

  /// Converts this host function to its XDR representation.
  ///
  /// Returns: XDR host function for contract creation.
  @override
  XdrHostFunction toXdr() {
    return XdrHostFunction.forCreatingContract(address.toXdr(), salt, wasmId);
  }
}

/// Creates a contract instance with constructor initialization arguments.
///
/// This host function deploys a contract that requires constructor arguments
/// for initialization. It combines contract creation with immediate initialization,
/// allowing contracts to set up initial state, validate parameters, and configure
/// permissions during deployment.
///
/// Constructor Arguments:
/// - **Initialization**: Pass arguments to contract constructor
/// - **State Setup**: Initialize contract storage during creation
/// - **Validation**: Constructor can validate deployment parameters
/// - **Authorization**: Can require specific signers for deployment
///
/// Constructor Use Cases:
/// - Set initial owner or admin addresses
/// - Configure contract parameters at deployment
/// - Initialize token supply or metadata
/// - Establish access control rules
/// - Link to other contracts or resources
///
/// Example - Deploy Contract with Constructor:
/// ```dart
/// // Create constructor arguments
/// var ownerAddress = Address.forAccountId(ownerAccountId);
/// var initialSupply = XdrSCVal.forU64(1000000);
/// var tokenName = XdrSCVal.forString("MyToken");
///
/// var constructorArgs = [
///   ownerAddress.toXdrSCVal(),
///   initialSupply,
///   tokenName
/// ];
///
/// var deployerAddress = Address.forAccountId(deployerAccountId);
///
/// var createFunction = CreateContractWithConstructorHostFunction(
///   deployerAddress,
///   wasmId,
///   constructorArgs
/// );
///
/// var createOp = InvokeHostFuncOpBuilder(createFunction)
///   .setSourceAccount(deployerAccountId)
///   .build();
/// ```
///
/// Important Considerations:
/// - Constructor args must match contract's constructor signature
/// - Constructor execution costs included in deployment fees
/// - Constructor can fail, reverting deployment
/// - Arguments are type-checked by the contract
/// - Consider authorization requirements for constructor
///
/// See also:
/// - [CreateContractHostFunction] for contracts without constructor
/// - [UploadContractWasmHostFunction] to upload WASM first
/// - [InvokeContractHostFunction] to call contract functions
class CreateContractWithConstructorHostFunction extends HostFunction {
  Address _address;

  /// The address of the deployer (account or contract).
  Address get address => this._address;
  set address(Address value) => this._address = value;

  String _wasmId;

  /// The hex-encoded hash of the uploaded WASM code.
  String get wasmId => this._wasmId;
  set wasmId(String value) => this._wasmId = value;

  List<XdrSCVal> _constructorArgs;

  /// Constructor arguments passed to the contract during creation.
  List<XdrSCVal> get constructorArgs => this._constructorArgs;
  set constructorArgs(List<XdrSCVal> value) => this._constructorArgs = value;

  late XdrUint256 _salt;

  /// Random salt for unique contract ID generation.
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  /// Creates a CreateContractWithConstructorHostFunction.
  ///
  /// Parameters:
  /// - [_address]: Deployer address (account or contract).
  /// - [_wasmId]: Hash of previously uploaded WASM code.
  /// - [_constructorArgs]: Arguments passed to contract constructor.
  /// - [salt]: Optional salt for contract ID (generated if not provided).
  CreateContractWithConstructorHostFunction(this._address, this._wasmId, this._constructorArgs, {XdrUint256? salt}) {
    if (salt != null) {
      this._salt = salt;
    } else {
      this._salt = new XdrUint256(TweetNaCl.randombytes(32));
    }
  }

  /// Converts this host function to its XDR representation.
  ///
  /// Returns: XDR host function for contract creation with constructor.
  @override
  XdrHostFunction toXdr() {
    return XdrHostFunction.forCreatingContractV2(address.toXdr(), salt, wasmId, constructorArgs);
  }
}

/// Deploys a Stellar Asset Contract (SAC) for the source account.
///
/// This host function creates a Stellar Asset Contract that wraps a classic
/// Stellar asset, enabling it to be used in Soroban smart contracts. The SAC
/// is deployed using the source account's identity, creating a contract that
/// represents the account's native balance or issued assets.
///
/// Stellar Asset Contracts (SAC):
/// - **Bridge**: Connects classic Stellar assets to Soroban contracts
/// - **Standard Interface**: Provides token interface for classic assets
/// - **Interoperability**: Allows DeFi contracts to use Stellar assets
/// - **Trustlines**: Maintains classic trustline semantics
///
/// Source Account SAC:
/// - Deploys SAC using account as asset issuer
/// - Useful for creating wrapped native balances
/// - Contract ID derived from account address and salt
/// - Represents assets issued by the account
///
/// Use Cases:
/// - Wrap account's issued assets for Soroban use
/// - Enable smart contract access to classic assets
/// - Build DeFi protocols using existing assets
/// - Create liquidity pools with classic assets
///
/// Example - Deploy SAC for Account:
/// ```dart
/// var accountAddress = Address.forAccountId(issuerAccountId);
///
/// var deploySACFunction = DeploySACWithSourceAccountHostFunction(
///   accountAddress
/// );
///
/// var deployOp = InvokeHostFuncOpBuilder(deploySACFunction)
///   .setSourceAccount(issuerAccountId)
///   .build();
///
/// var transaction = TransactionBuilder(issuerAccount)
///   .addOperation(deployOp)
///   .setSorobanData(footprint)
///   .build();
/// ```
///
/// Important Considerations:
/// - One SAC per asset-account combination
/// - SAC maintains classic asset semantics
/// - Requires trustlines for non-native assets
/// - Contract ID is deterministic
/// - Standard token interface compatibility
///
/// See also:
/// - [DeploySACWithAssetHostFunction] to deploy SAC from specific asset
/// - [InvokeContractHostFunction] to interact with deployed SAC
class DeploySACWithSourceAccountHostFunction extends HostFunction {
  Address _address;

  /// The source account address that will be used for SAC deployment.
  Address get address => this._address;
  set address(Address value) => this._address = value;

  late XdrUint256 _salt;

  /// Random salt for unique contract ID generation.
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  /// Creates a DeploySACWithSourceAccountHostFunction.
  ///
  /// Parameters:
  /// - [_address]: Source account address for SAC deployment.
  /// - [salt]: Optional salt for contract ID (generated if not provided).
  DeploySACWithSourceAccountHostFunction(this._address, {XdrUint256? salt}) {
    if (salt != null) {
      this._salt = salt;
    } else {
      this._salt = new XdrUint256(TweetNaCl.randombytes(32));
    }
  }

  /// Converts this host function to its XDR representation.
  ///
  /// Returns: XDR host function for SAC deployment from source account.
  @override
  XdrHostFunction toXdr() {
    return XdrHostFunction.forDeploySACWithSourceAccount(address.toXdr(), salt);
  }
}

/// Deploys a Stellar Asset Contract (SAC) for a specific classic asset.
///
/// This host function creates a Stellar Asset Contract that wraps a specific
/// classic Stellar asset (native XLM or issued asset), making it accessible to
/// Soroban smart contracts. The SAC provides a standard token interface for
/// interacting with the classic asset within the smart contract environment.
///
/// Stellar Asset Contracts (SAC):
/// - **Asset Wrapping**: Bridges classic assets to Soroban contracts
/// - **Standard Interface**: Implements Soroban token standard
/// - **Native Support**: Can wrap XLM (native asset)
/// - **Issued Assets**: Can wrap any classic issued asset
///
/// Asset Types:
/// - **Native (XLM)**: Stellar's native cryptocurrency
/// - **Credit Assets**: Issued assets with code and issuer
/// - **Alphanumeric 4**: Asset codes up to 4 characters
/// - **Alphanumeric 12**: Asset codes up to 12 characters
///
/// Use Cases:
/// - Enable DeFi protocols with classic assets
/// - Create DEX contracts using Stellar assets
/// - Build lending/borrowing with existing assets
/// - Integrate classic liquidity into smart contracts
///
/// Example - Deploy SAC for USDC:
/// ```dart
/// // Deploy SAC for a classic USDC asset
/// var usdcAsset = AssetTypeCreditAlphaNum4(
///   "USDC",
///   usdcIssuerAccountId
/// );
///
/// var deploySACFunction = DeploySACWithAssetHostFunction(usdcAsset);
///
/// var deployOp = InvokeHostFuncOpBuilder(deploySACFunction)
///   .setSourceAccount(deployerAccountId)
///   .build();
///
/// var transaction = TransactionBuilder(deployerAccount)
///   .addOperation(deployOp)
///   .setSorobanData(footprint)
///   .build();
/// ```
///
/// Example - Deploy SAC for Native XLM:
/// ```dart
/// var deploySACFunction = DeploySACWithAssetHostFunction(AssetTypeNative());
///
/// var deployOp = InvokeHostFuncOpBuilder(deploySACFunction)
///   .setSourceAccount(deployerAccountId)
///   .build();
/// ```
///
/// Important Considerations:
/// - One SAC per asset (deterministic contract ID)
/// - Maintains trustline requirements
/// - Standard Soroban token interface
/// - Compatible with existing DeFi protocols
/// - Gas costs for deployment
///
/// See also:
/// - [DeploySACWithSourceAccountHostFunction] for account-based SAC
/// - [InvokeContractHostFunction] to interact with deployed SAC
/// - [Asset] for classic asset types
class DeploySACWithAssetHostFunction extends HostFunction {
  Asset _asset;

  /// The classic Stellar asset to wrap in a contract.
  Asset get asset => this._asset;
  set asset(Asset value) => this._asset = value;

  /// Creates a DeploySACWithAssetHostFunction.
  ///
  /// Parameters:
  /// - [_asset]: Classic Stellar asset (native or issued) to wrap.
  DeploySACWithAssetHostFunction(this._asset);

  /// Converts this host function to its XDR representation.
  ///
  /// Returns: XDR host function for SAC deployment from asset.
  @override
  XdrHostFunction toXdr() {
    return XdrHostFunction.forDeploySACWithAsset(asset.toXdr());
  }
}

/// Invokes a function on a deployed Soroban smart contract.
///
/// This host function calls a specific function on a deployed contract, passing
/// arguments and receiving return values. Contract invocations can read/write
/// contract state, call other contracts, and interact with classic Stellar
/// operations through authorization.
///
/// Contract Invocation:
/// - **Contract ID**: Identifies the target contract
/// - **Function Name**: Name of the contract function to call
/// - **Arguments**: Typed parameters passed to the function
/// - **Return Value**: Result returned by the contract function
///
/// Function Execution:
/// - Executes within Soroban WASM environment
/// - Can read and modify contract state
/// - Can make sub-calls to other contracts
/// - Requires proper authorization for restricted operations
/// - Consumes CPU and memory resources
///
/// Authorization:
/// - **Signature Authorization**: User signs transaction
/// - **Contract Authorization**: Contract authorizes sub-invocations
/// - **Multi-party**: Multiple signatures for complex operations
/// - **Replay Protection**: Nonces prevent transaction replay
///
/// Use Cases:
/// - Transfer tokens in DeFi protocols
/// - Execute swaps on DEX contracts
/// - Update contract state
/// - Query contract data
/// - Orchestrate multi-contract workflows
///
/// Example - Invoke Token Transfer:
/// ```dart
/// // Prepare transfer arguments
/// var fromAddress = Address.forAccountId(fromAccountId);
/// var toAddress = Address.forAccountId(toAccountId);
/// var amount = XdrSCVal.forI128(XdrInt128Parts(1000000, 0));
///
/// var invokeFunction = InvokeContractHostFunction(
///   tokenContractId,
///   "transfer",
///   arguments: [
///     fromAddress.toXdrSCVal(),
///     toAddress.toXdrSCVal(),
///     amount
///   ]
/// );
///
/// var invokeOp = InvokeHostFuncOpBuilder(invokeFunction)
///   .setAuth(authorizationEntries)
///   .setSourceAccount(fromAccountId)
///   .build();
/// ```
///
/// Example - Query Contract State:
/// ```dart
/// var balanceQuery = InvokeContractHostFunction(
///   tokenContractId,
///   "balance",
///   arguments: [Address.forAccountId(accountId).toXdrSCVal()]
/// );
///
/// var queryOp = InvokeHostFuncOpBuilder(balanceQuery).build();
/// ```
///
/// Important Considerations:
/// - Function name must match contract export
/// - Arguments must match expected types
/// - Authorization required for state changes
/// - Gas costs based on computation complexity
/// - Return values parsed from XDR
/// - Contract errors cause transaction failure
///
/// See also:
/// - [SorobanAuthorizationEntry] for authorization
/// - [InvokeHostFuncOpBuilder] to build invocation operations
/// - [CreateContractHostFunction] to deploy contracts first
class InvokeContractHostFunction extends HostFunction {
  String _contractID;

  /// The contract ID (C-prefixed address or hex format).
  String get contractID => this._contractID;
  set contractID(String value) => this._contractID = value;

  String _functionName;

  /// The name of the contract function to invoke.
  String get functionName => this._functionName;
  set functionName(String value) => this._functionName = value;

  /// Optional arguments to pass to the contract function.
  List<XdrSCVal>? arguments;

  /// Creates an InvokeContractHostFunction.
  ///
  /// Parameters:
  /// - [_contractID]: Contract address (C-format or hex).
  /// - [_functionName]: Name of the function to invoke.
  /// - [arguments]: Optional list of arguments for the function.
  InvokeContractHostFunction(this._contractID, this._functionName,
      {this.arguments});

  /// Converts this host function to its XDR representation.
  ///
  /// Returns: XDR host function for contract invocation.
  ///
  /// Throws: Exception if contract ID cannot be converted to address.
  @override
  XdrHostFunction toXdr() {
    List<XdrSCVal> fcArgs = List<XdrSCVal>.empty(growable: true);

    if (this.arguments != null) {
      fcArgs.addAll(this.arguments!);
    }
    // can be any type of address.
    final address = addressFromId(contractID);
    if (address == null) {
      throw new Exception("Could not convert contract id: $contractID to address");
    }
    XdrInvokeContractArgs args = XdrInvokeContractArgs(
        address.toXdr(),
        this._functionName,
        fcArgs);
    return XdrHostFunction.forInvokingContractWithArgs(args);
  }
}

/// Builder for [InvokeHostFunctionOperation].
///
/// Provides a fluent interface for constructing Soroban host function invocations
/// with proper authorization and source account configuration.
///
/// Builder Pattern:
/// - **Host Function**: Specify the operation (invoke, deploy, upload)
/// - **Authorization**: Add authorization entries for multi-party operations
/// - **Source Account**: Set the account paying for execution
///
/// Authorization Entries:
/// Authorization entries prove that accounts or contracts approve the operation.
/// Required for operations that:
/// - Transfer assets from accounts
/// - Modify account-controlled state
/// - Perform restricted contract operations
/// - Execute multi-signature workflows
///
/// Example - Build Contract Invocation:
/// ```dart
/// var invokeFunction = InvokeContractHostFunction(
///   contractId,
///   "transfer",
///   arguments: [fromAddr, toAddr, amount]
/// );
///
/// var operation = InvokeHostFuncOpBuilder(invokeFunction)
///   .setAuth(authorizationEntries)
///   .setSourceAccount(sourceAccountId)
///   .build();
/// ```
///
/// Example - Build Contract Deployment:
/// ```dart
/// var uploadFunction = UploadContractWasmHostFunction(wasmBytes);
///
/// var operation = InvokeHostFuncOpBuilder(uploadFunction)
///   .setSourceAccount(deployerAccountId)
///   .build();
/// ```
///
/// See also:
/// - [InvokeHostFunctionOperation] for the resulting operation
/// - [SorobanAuthorizationEntry] for authorization details
/// - [HostFunction] for different function types
class InvokeHostFuncOpBuilder {
  MuxedAccount? _mSourceAccount;

  HostFunction _function;

  /// The host function to execute (invoke, deploy, upload, etc.).
  HostFunction get function => this._function;
  set function(HostFunction value) => this._function = value;

  /// Authorization entries proving approval for restricted operations.
  List<SorobanAuthorizationEntry> auth =
      List<SorobanAuthorizationEntry>.empty(growable: true);

  /// Creates an InvokeHostFuncOpBuilder.
  ///
  /// Parameters:
  /// - [_function]: The host function to execute.
  /// - [auth]: Optional authorization entries for the operation.
  InvokeHostFuncOpBuilder(this._function,
      {List<SorobanAuthorizationEntry>? auth}) {
    if (auth != null) {
      this.auth = auth;
    }
  }

  /// Sets the host function for this operation.
  ///
  /// Parameters:
  /// - [hostFunction]: The host function to execute.
  ///
  /// Returns: This builder instance for method chaining.
  InvokeHostFuncOpBuilder setHostFunction(HostFunction hostFunction) {
    this._function = hostFunction;
    return this;
  }

  /// Sets authorization entries for this operation.
  ///
  /// Authorization entries prove that accounts or contracts approve the
  /// operation, required for restricted operations like asset transfers.
  ///
  /// Parameters:
  /// - [authEntries]: List of authorization entries.
  ///
  /// Returns: This builder instance for method chaining.
  InvokeHostFuncOpBuilder setAuth(List<SorobanAuthorizationEntry> authEntries) {
    this.auth = authEntries;
    return this;
  }

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID paying for operation execution.
  ///
  /// Returns: This builder instance for method chaining.
  InvokeHostFuncOpBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount]: The muxed source account.
  ///
  /// Returns: This builder instance for method chaining.
  InvokeHostFuncOpBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the invoke host function operation.
  ///
  /// Returns: A configured [InvokeHostFunctionOperation] instance.
  InvokeHostFunctionOperation build() {
    InvokeHostFunctionOperation op =
        InvokeHostFunctionOperation(function, auth: auth);
    op.sourceAccount = _mSourceAccount;
    return op;
  }
}

/// Invokes a Soroban smart contract host function.
///
/// This operation executes smart contract functions on the Stellar network, enabling
/// complex programmable logic beyond classic operations. Soroban contracts are written
/// in Rust (or other WASM-compatible languages) and compiled to WebAssembly.
///
/// Operation Types:
/// - **Contract Invocation**: Call functions on deployed contracts
/// - **Contract Deployment**: Deploy new contract instances
/// - **WASM Upload**: Upload contract bytecode
/// - **SAC Deployment**: Deploy Stellar Asset Contracts for classic assets
///
/// Requirements:
/// - Transaction must include Soroban footprint (ledger keys accessed)
/// - Must specify resource limits (CPU instructions, memory, etc.)
/// - Authorization entries for multi-party operations
/// - Sufficient fee budget for contract execution
///
/// Example - Invoke Contract Function:
/// ```dart
/// var invokeFunction = InvokeContractHostFunction(
///   contractId,
///   "transfer",
///   arguments: [fromAddress, toAddress, amount]
/// );
///
/// var invokeOp = InvokeHostFuncOpBuilder(invokeFunction)
///   .setAuth(authorizationEntries)
///   .setSourceAccount(accountId)
///   .build();
/// ```
///
/// See also:
/// - [HostFunction] for different host function types
/// - [RestoreFootprintOperation] for state restoration
/// - [ExtendFootprintTTLOperation] for TTL management
class InvokeHostFunctionOperation extends Operation {
  HostFunction _function;

  /// The host function to execute (invoke, deploy, upload, etc.).
  HostFunction get function => this._function;
  set function(HostFunction value) => this._function = value;

  /// Authorization entries for multi-party or restricted operations.
  List<SorobanAuthorizationEntry> auth =
      List<SorobanAuthorizationEntry>.empty(growable: true);

  /// Creates an InvokeHostFunctionOperation.
  ///
  /// Parameters:
  /// - [_function]: The host function to execute.
  /// - [auth]: Optional authorization entries for the operation.
  InvokeHostFunctionOperation(this._function,
      {List<SorobanAuthorizationEntry>? auth}) {
    if (auth != null) {
      this.auth = auth;
    }
  }

  /// Creates a builder from an XDR invoke host function operation.
  ///
  /// Parameters:
  /// - [op]: XDR invoke host function operation.
  ///
  /// Returns: Builder initialized with operation parameters.
  static InvokeHostFuncOpBuilder builder(XdrInvokeHostFunctionOp op) {
    List<SorobanAuthorizationEntry> auth =
        List<SorobanAuthorizationEntry>.empty(growable: true);
    for (XdrSorobanAuthorizationEntry aXdr in op.auth) {
      auth.add(SorobanAuthorizationEntry.fromXdr(aXdr));
    }
    return InvokeHostFuncOpBuilder(HostFunction.fromXdr(op.function),
        auth: auth);
  }

  /// Converts this operation to its XDR representation.
  ///
  /// Returns: XDR operation body for the host function invocation.
  @override
  XdrOperationBody toOperationBody() {
    List<XdrSorobanAuthorizationEntry> xdrAuth =
        List<XdrSorobanAuthorizationEntry>.empty(growable: true);
    for (SorobanAuthorizationEntry a in auth) {
      xdrAuth.add(a.toXdr());
    }
    XdrInvokeHostFunctionOp xdrOp =
        XdrInvokeHostFunctionOp(function.toXdr(), xdrAuth);
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.INVOKE_HOST_FUNCTION);
    body.invokeHostFunctionOp = xdrOp;
    return body;
  }
}
