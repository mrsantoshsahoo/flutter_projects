import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_it/new_ui/connect_screen.dart';
import 'chat_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _images = [];
  List<Uint8List?> _thumbnails = []; // Store thumbnail data
  List<AssetEntity> _selectedImages = []; // To hold selected images
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    final permissionStatus = await PhotoManager.requestPermissionExtend();
    if (permissionStatus.isAuth) {
      final List<AssetEntity> resultList =
          await PhotoManager.getAssetListRange(start: 0, end: 100);
      setState(() {
        _images = resultList;
        _thumbnails =
            List.filled(resultList.length, null); // Initialize thumbnails list
      });

      // Fetch thumbnails
      for (int i = 0; i < _images.length; i++) {
        final thumbData = await _images[i].thumbnailData;
        setState(() {
          _thumbnails[i] = thumbData; // Store fetched thumbnail data
        });
      }
    } else {
      // Handle permission denial
      print('Permission Denied');
    }
  }

  void _toggleSelection(AssetEntity image) {
    setState(() {
      if (_selectedImages.contains(image)) {
        _selectedImages.remove(image);
      } else {
        _selectedImages.add(image);
      }
    });
  }

  void _sendImages() {
    // Implement your sending logic here
    if (_selectedImages.isNotEmpty) {
      final selectedImageIds =
          _selectedImages.map((image) => image.id).toList();
      print("Selected Images: $selectedImageIds");
      // Here you can add the logic to send the images
    } else {
      print("No images selected.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _images.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: EdgeInsets.all(1),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 1.5,
                            mainAxisSpacing: 1.5),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _toggleSelection(_images[index]);
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          fit: StackFit.expand,
                          children: [
                            _thumbnails[index] != null
                                ? Image.memory(
                                    _thumbnails[index]!,
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: CircularProgressIndicator()),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Checkbox(
                                value: _selectedImages.contains(_images[index]),
                                onChanged: (v) {},
                                checkColor: Colors.black,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                activeColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          ElevatedButton(
            onPressed: _sendImages,
            child: const Text('Send Selected Images'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) async {
          currentPageIndex = index;

          if (index == 1) {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const ConnectScreen()));
            currentPageIndex = 0;
          }
          setState(() {});
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.share)),
            label: 'Share',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('2'),
              child: Icon(Icons.messenger_sharp),
            ),
            label: 'Messages',
          ),
        ],
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildConnectionInput(chatProvider),
            Expanded(child: _buildMessagesList(chatProvider)),
            _buildMessageInput(chatProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInput(ChatProvider chatProvider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: chatProvider.hostController,
            decoration: const InputDecoration(labelText: 'Host'),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  chatProvider.startServer();
                },
                child: const Text('Start Server'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  chatProvider.connectToServer();
                },
                child: const Text('Connect to Server'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatProvider chatProvider) {
    return ListView.builder(
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.messages[index];
        if (message.type == MessageType.text) {
          return ListTile(title: Text(message.message ?? ''));
        } else if (message.type == MessageType.image &&
            message.mediaData != null) {
          return ListTile(
            title: Text('Image: ${message.fileName}'),
            subtitle: Image.memory(message.mediaData!),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => chatProvider.sendImage(),
            icon: const Icon(Icons.add_a_photo),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: chatProvider.messageController,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              chatProvider.sendMessage();
              chatProvider.messageController.clear();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
