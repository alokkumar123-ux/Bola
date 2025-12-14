import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/review_model.dart';

class ReviewUtils {
  static final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  static Future<List<ReviewModel>?> getRating(String reviewReceivedId) async {
    List<ReviewModel> taxList = [];

    await _fireStore
        .collection(CollectionName.review)
        .where('receiver_id', isEqualTo: reviewReceivedId)
        .orderBy("date", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ReviewModel taxModel = ReviewModel.fromJson(element.data());
        taxList.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return taxList;
  }

  static Future<ReviewModel?> getReview(
      {required String bookingId, required String senderId}) async {
    ReviewModel? reviewModel;
    await _fireStore
        .collection(CollectionName.review)
        .where('booking_id', isEqualTo: bookingId)
        .where(
          'sender_id',
          isEqualTo: senderId,
        )
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        reviewModel = ReviewModel.fromJson(value.docs.first.data());
      }
    });
    return reviewModel;
  }

  static Future<ReviewModel?> getReviewByReceiverId(
      {required String bookingId, required String receiverId}) async {
    ReviewModel? reviewModel;
    await _fireStore
        .collection(CollectionName.review)
        .where('booking_id', isEqualTo: bookingId)
        .where(
          'receiver_id',
          isEqualTo: receiverId,
        )
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        reviewModel = ReviewModel.fromJson(value.docs.first.data());
      }
    });
    return reviewModel;
  }

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    bool isAdded = false;
    await _fireStore
        .collection(CollectionName.review)
        .doc(reviewModel.id)
        .set(reviewModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }
}
