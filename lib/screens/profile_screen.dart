import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  Widget _decorLine(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 3,
          decoration: BoxDecoration(
            color: Theme.of(context).shadowColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Positioned(
          left: 0,
          top: 7.5,
          child: Container(
            width: 15, // Example width for the progress bar
            height: 15,
            decoration: BoxDecoration(
              color: Theme.of(context).shadowColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: double.infinity, height: 30),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context,
    double width, {
    String title = 'Title',
    String value = 'Value',
  }) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: width * 0.3,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(50),
            ),
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(width: 30),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).shadowColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Stack(
              children: [
                Positioned(
                  top: -height * 0.3,
                  left: -width * 0.1,
                  child: Container(
                    width: width * 1.5,
                    height: width * 1.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                    ),
                  ),
                ),
                Positioned(
                  top: height * 0.25,
                  left: width * 0.05,
                  child: Container(
                    width: width * 0.3,
                    height: width * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).shadowColor,
                    ),
                  ),
                ),
                Container(width: width, height: height / 2.5),
              ],
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  Text(
                    'Abdelrahman Mohammed Mosaad',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).shadowColor,
                      fontSize: 32,
                    ),
                    softWrap: true,
                  ),
                  SizedBox(height: 10),
                  _decorLine(context),
                  SizedBox(height: 10),
                  _infoCard(context, width, title: 'Role', value: 'Student'),
                  SizedBox(height: 10),
                  _infoCard(
                    context,
                    width,
                    title: 'Email',
                    value: 'abdelrahman@example.com',
                  ),
                  SizedBox(height: 10),
                  _infoCard(context, width, title: 'Grade', value: '1st Year'),
                  SizedBox(height: 10),
                  _infoCard(
                    context,
                    width,
                    title: 'Department',
                    value: 'Communication Engineering',
                  ),
                  SizedBox(height: 10),
                  _infoCard(
                    context,
                    width,
                    title: 'Field of specialization',
                    value: 'Physics',
                  ),
                  SizedBox(height: 10),
                  _decorLine(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
