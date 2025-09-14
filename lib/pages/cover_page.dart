import 'package:flutter/material.dart';

class CoverPage extends StatelessWidget {
  const CoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      backgroundColor: const Color(0xFFde3163),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenSize.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main Title - Bold with black color
                  Text(
                    'Humbowo Hutsva',
                    style: TextStyle(
                      fontSize: isLandscape ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.2,
                      fontFamily: 'Times New Roman',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isLandscape ? 12 : 20),

                  // Subtitle with black color
                  Text(
                    'HwevaPostori',
                    style: TextStyle(
                      fontSize: isLandscape ? 18 : 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      letterSpacing: 0.8,
                      fontFamily: 'Times New Roman',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isLandscape ? 20 : 40),

                  // Photo Container - responsive size
                  Container(
                    width: isLandscape
                        ? screenSize.height * 0.25
                        : screenSize.width * 0.5,
                    height: isLandscape
                        ? screenSize.height * 0.35
                        : screenSize.width * 0.65,
                    constraints: BoxConstraints(
                      maxWidth: 200,
                      maxHeight: 250,
                      minWidth: 120,
                      minHeight: 150,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/John_Marange_the_Baptist.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Photo',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: isLandscape ? 20 : 40),

                  // Author Information with black text
                  Column(
                    children: [
                      Text(
                        'JOHN MARANGE MUBHABHATIDZI',
                        style: TextStyle(
                          fontSize: isLandscape ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                          fontFamily: 'Times New Roman',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isLandscape ? 8 : 12),

                      Text(
                        'MWANA WAMOMBERUME',
                        style: TextStyle(
                          fontSize: isLandscape ? 14 : 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                          fontFamily: 'Times New Roman',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isLandscape ? 8 : 12),

                      Text(
                        'BOCHA KWAMARANGE',
                        style: TextStyle(
                          fontSize: isLandscape ? 14 : 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                          fontFamily: 'Times New Roman',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  SizedBox(height: isLandscape ? 20 : 30),

                  Padding(
                    padding: EdgeInsets.only(bottom: isLandscape ? 20 : 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Material(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white,
                        elevation: 3,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          splashColor: const Color(0xFFde3163).withOpacity(0.3),
                          highlightColor: const Color(
                            0xFFde3163,
                          ).withOpacity(0.1),
                          onTap: () {
                            Navigator.pushNamed(context, '/chapters');
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Center(
                              child: Text(
                                'Continue Reading',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Times New Roman',
                                  color: Color(0xFFde3163),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
