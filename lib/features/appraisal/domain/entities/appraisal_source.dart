import 'package:equatable/equatable.dart';

/// A single source URL cited by the Appraiser LLM response.
class AppraisalSource extends Equatable {
  final String url;
  final String title;
  final double? price;

  const AppraisalSource({required this.url, required this.title, this.price});

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    if (price != null) 'price': price,
  };

  factory AppraisalSource.fromJson(Map<String, dynamic> j) => AppraisalSource(
    url: j['url'] as String? ?? '',
    title: j['title'] as String? ?? '',
    price: (j['price'] as num?)?.toDouble(),
  );

  @override
  List<Object?> get props => [url, title, price];
}
