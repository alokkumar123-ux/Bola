import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/wallet_transaction_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';

/// Wallet and transaction management utilities
class WalletUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  /// Update wallet of other user
  static Future<bool?> updateOtherUserWallet(
      {required String amount, required String id}) async {
    bool isAdded = false;
    try {
      final userModel = await UserUtils.getUserProfile(id);
      if (userModel != null) {
        double currentWallet =
            double.tryParse(userModel.walletAmount?.toString() ?? '0') ?? 0;
        double amountToAdd = double.tryParse(amount) ?? 0;
        userModel.walletAmount =
            (currentWallet + amountToAdd).toStringAsFixed(2);

        print(
            'Updating wallet for user $id: $currentWallet + $amountToAdd = ${userModel.walletAmount}');

        isAdded = await UserUtils.updateUser(userModel);
        if (isAdded) {
          print(
              '✅ Wallet updated for user $id. New balance: ${userModel.walletAmount}');
        } else {
          print('❌ Failed to update wallet for user $id');
        }
      } else {
        print('❌ User not found: $id');
        isAdded = false;
      }
    } catch (e) {
      print('❌ Error updating wallet: $e');
      isAdded = false;
    }
    return isAdded;
  }

  /// Update current user's wallet
  static Future<bool?> updateUserWallet({required String amount}) async {
    bool isAdded = false;
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid())
        .then((value) async {
      if (value != null) {
        UserModel userModel = value;
        userModel.walletAmount =
            (double.parse(userModel.walletAmount.toString()) +
                    double.parse(amount))
                .toString();
        await UserUtils.updateUser(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  /// Deduct money from user wallet with balance validation
  static Future<Map<String, dynamic>> deductFromUserWallet({
    required String amount,
    required String userId,
    required String description,
  }) async {
    try {
      double deductAmount = double.parse(amount);

      UserModel? userModel = await UserUtils.getUserProfile(userId);
      if (userModel == null) {
        return {
          'success': false,
          'message': 'User not found',
          'code': 'USER_NOT_FOUND'
        };
      }

      double currentBalance = double.parse(userModel.walletAmount ?? '0');

      if (currentBalance < deductAmount) {
        return {
          'success': false,
          'message':
              'Insufficient wallet balance. Available: ${currentBalance.toStringAsFixed(2)}',
          'code': 'INSUFFICIENT_BALANCE',
          'availableBalance': currentBalance
        };
      }

      double newBalance = currentBalance - deductAmount;
      userModel.walletAmount = newBalance.toString();

      bool isUpdated = await UserUtils.updateUser(userModel);

      if (isUpdated) {
        WalletTransactionModel transactionModel = WalletTransactionModel(
            id: Constant.getUuid(),
            amount: amount,
            createdDate: Timestamp.now(),
            paymentType: 'Wallet',
            transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            isCredit: false,
            note: description,
            type: 'customer');

        await setWalletTransaction(transactionModel);

        return {
          'success': true,
          'message': 'Payment processed successfully',
          'code': 'PAYMENT_SUCCESS',
          'newBalance': newBalance,
          'transactionId': transactionModel.transactionId
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update wallet balance',
          'code': 'UPDATE_FAILED'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Payment processing error: $e',
        'code': 'PROCESSING_ERROR'
      };
    }
  }

  /// Add money to driver's wallet
  static Future<Map<String, dynamic>> addToDriverWallet({
    required String amount,
    required String driverId,
    required String bookingId,
    required String description,
  }) async {
    try {
      double addAmount = double.parse(amount);

      UserModel? driverModel = await UserUtils.getUserProfile(driverId);
      if (driverModel == null) {
        return {
          'success': false,
          'message': 'Driver not found',
          'code': 'DRIVER_NOT_FOUND'
        };
      }

      double currentBalance = double.parse(driverModel.walletAmount ?? '0');
      double newBalance = currentBalance + addAmount;
      driverModel.walletAmount = newBalance.toString();

      bool isUpdated = await UserUtils.updateUser(driverModel);

      if (isUpdated) {
        WalletTransactionModel transactionModel = WalletTransactionModel(
            id: Constant.getUuid(),
            amount: amount,
            createdDate: Timestamp.now(),
            paymentType: 'Ride Payment',
            transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: driverId,
            isCredit: true,
            note: description,
            type: 'customer');

        await setWalletTransaction(transactionModel);

        return {
          'success': true,
          'message': 'Payment transferred to driver successfully',
          'code': 'TRANSFER_SUCCESS',
          'newBalance': newBalance,
          'transactionId': transactionModel.transactionId
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update driver wallet balance',
          'code': 'UPDATE_FAILED'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Driver payment transfer error: $e',
        'code': 'TRANSFER_ERROR'
      };
    }
  }

  /// Record admin commission
  static Future<Map<String, dynamic>> recordAdminCommission({
    required String amount,
    required String bookingId,
    required String description,
    required String passengerId,
    required String driverId,
  }) async {
    try {
      Map<String, dynamic> adminEarningsData = {
        'id': Constant.getUuid(),
        'amount': amount,
        'bookingId': bookingId,
        'description': description,
        'passengerId': passengerId,
        'driverId': driverId,
        'createdAt': Timestamp.now(),
        'type': 'commission',
        'status': 'earned',
      };

      await fireStore
          .collection('admin_earnings')
          .doc(adminEarningsData['id'])
          .set(adminEarningsData);

      return {
        'success': true,
        'message': 'Admin commission recorded successfully',
        'code': 'COMMISSION_RECORDED'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to record admin commission: $e',
        'code': 'COMMISSION_ERROR'
      };
    }
  }

  /// Create wallet transaction
  static Future<bool?> setWalletTransaction(
      WalletTransactionModel walletTransactionModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.walletTransaction)
        .doc(walletTransactionModel.id)
        .set(walletTransactionModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      print("Failed to create wallet transaction: $error");
      isAdded = false;
    });
    return isAdded;
  }

  /// Get wallet transactions
  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionModel = [];

    await fireStore
        .collection(CollectionName.walletTransaction)
        .where('userId', isEqualTo: AuthUtils.getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        walletTransactionModel
            .add(WalletTransactionModel.fromJson(element.data()));
      }
    }).catchError((error) {
      print(error.toString());
    });
    return walletTransactionModel;
  }
}
