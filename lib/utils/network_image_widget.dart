import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/themes/responsive.dart';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? borderRadius;
  final Color? color;
  final FilterQuality filterQuality;

  const NetworkImageWidget({
    super.key,
    this.height,
    this.width,
    this.fit,
    required this.imageUrl,
    this.borderRadius,
    this.errorWidget,
    this.color,
    this.filterQuality = FilterQuality.low,
  });

  @override
  Widget build(BuildContext context) {
    final String sanitizedUrl = imageUrl.trim();

    if (sanitizedUrl.isEmpty) {
      return Image.asset(
        Constant.getStartedImage,
        fit: fit ?? BoxFit.fitWidth,
        height: height ?? Responsive.height(8, context),
        width: width ?? Responsive.width(15, context),
      );
    }

    return CachedNetworkImage(
      imageUrl: sanitizedUrl,
      fit: fit ?? BoxFit.cover,
      height: height ?? Responsive.height(8, context),
      width: width ?? Responsive.width(15, context),
      color: color,
      filterQuality: filterQuality,
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          Center(child: Constant.loader()),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Image.asset(
            Constant.getStartedImage,
            fit: fit ?? BoxFit.fitWidth,
            height: height ?? Responsive.height(8, context),
            width: width ?? Responsive.width(15, context),
          ),
    );
  }
}
