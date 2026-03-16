// resource_module/resourcesViews/newsViews/AllNews.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../annim/transiton.dart';
import '../../providers/newsProvider.dart';
import 'newsDetail.dart';
import '../../constants/AppConstants.dart';

class AllNews extends StatefulWidget {
  @override
  State<AllNews> createState() => _AllNewsState();
}

class _AllNewsState extends State<AllNews> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    await Future.delayed(Duration.zero);
    Provider.of<BulletinProvider>(context, listen: false)
        .fetchBulletinCollection(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF45A3D9), Color(0xFF45D9D0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(60),
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: const Text(
                    "General News Bulletins",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<BulletinProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            // Show a loading indicator while fetching data
            return Center(child: CircularProgressIndicator());
          }

          if (provider.bulletinResponse == null || provider.bulletinResponse!.data.isEmpty) {
            // Show a message if no bulletins are available
            return Center(
              child: Text(
                "No news bulletins available.",
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            );
          }

          // Display the list of bulletins
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.bulletinResponse!.data.length,
            itemBuilder: (BuildContext context, int index) {
              final bulletin = provider.bulletinResponse!.data[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  FadePageRouteBuilder(widget: NewsDetail(newsBulletin: bulletin)),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // News Icon
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF45A3D9), Color(0xFF45D9D0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              AppConstants.newsIcon,
                              height: 40,
                              width: 40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Bulletin Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bulletin.title ?? "No Title",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bulletin.content ?? "No Content",
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
