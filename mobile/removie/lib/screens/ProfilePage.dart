import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'HomePage.dart';
import 'EditProfilePage.dart';
import 'AdminDashboardPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "User"; // Default to "User" in case the token does not contain the username
  String profileImageUrl = "https://i.pinimg.com/736x/21/07/1b/21071b125bd4157a2723ad6e75d19ffa.jpg"; // Default profile image
  bool isAdmin = false; // To check if the user is an admin

  @override
  void initState() {
    super.initState();
    _getUsernameFromToken(); // Call the method to extract the username
  }

  // Function to get the username from the JWT token
  Future<void> _getUsernameFromToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token'); // Retrieve the token

    if (token != null && token.isNotEmpty) {
      // Decode the token and extract the username
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // Print the decoded token for debugging purposes
      print("Decoded Token: $decodedToken");

      // Extract the username from the decoded token
      setState(() {
        username = decodedToken['sub'] ?? "User"; // Ensure the key matches the token structure
        if (username == 'admin') {
          isAdmin = true;
        }
      });
    } else {
      print("No token found or token is empty");
    }
  }

  // Function to handle logout
  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Remove the token from shared preferences

    // Navigate to the home page after logging out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  // Function to delete account
  Future<void> deleteAccount(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();

    // Show confirmation dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please enter your password to confirm account deletion:"),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String password = passwordController.text;
              if (password.isNotEmpty) {
                // Make API call to delete account
                // Replace with your API call logic
                bool success = await deleteAccountApi(password);
                if (success) {
                  Navigator.of(context).pop();
                  logout(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
              ),
          ),
        ],
      ),
    );
  }

  Future<bool> deleteAccountApi(String password) async {
  const String apiUrl = "http://10.0.2.2:5000/api/auth/delete-account";

  try {
    // Retrieve the JWT token from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception("Authentication token not found.");
    }

    // Prepare the request body
    final body = json.encode({"password": password});

    // Make the HTTP DELETE request
    final response = await http.delete(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // Include the JWT token in the Authorization header
      },
      body: body,
    );

    if (response.statusCode == 200) {
      // Parse the response if needed
      final responseData = json.decode(response.body);
      print("Success: ${responseData['message']}");
      return true;
    } else if (response.statusCode == 400) {
      final responseData = json.decode(response.body);
      print("Error: ${responseData['message']}");
      return false;
    } else if (response.statusCode == 401) {
      print("Error: Unauthorized. Please check the token or user credentials.");
      return false;
    } else {
      print("Unexpected Error: ${response.statusCode}");
      return false;
    }
  } catch (e) {
    print("Exception occurred: $e");
    return false;
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Profile',
        style: TextStyle(color: Colors.white),
        ),
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
    ),
    body: Center( // Center the entire body
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Vertical center alignment
          crossAxisAlignment: CrossAxisAlignment.center, // Horizontal center alignment
          children: [
            // Display profile picture
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(profileImageUrl),
            ),
            const SizedBox(height: 20),
            // Display username
            Text(
              'Hello, $username!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            // Edit Profile button
            ElevatedButton(
              onPressed: () async {
                final updatedUsername = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                );

                // If updated username is not null, update the username state
                if (updatedUsername != null) {
                  setState(() {
                    username = updatedUsername;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(color: Colors.white), // Set the color to white
              ),
            ),
            const SizedBox(height: 20),
            // Admin Dashboard button
            if (isAdmin)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
              ),
            const SizedBox(height: 20),
            // Delete Account button
            ElevatedButton(
              onPressed: () => deleteAccount(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.white),
                ),
            ),
            const SizedBox(height: 20),
            // Logout button
            ElevatedButton(
              onPressed: () => logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.white),
                ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
