
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const ChristianApp());

class Song {
  String title, lyrics, category, videoUrl;
  bool favorite;
  Song({required this.title, required this.lyrics, required this.category,
    required this.videoUrl, this.favorite=false});
  Map<String,dynamic> toJson()=>{'title':title,'lyrics':lyrics,'category':category,'videoUrl':videoUrl,'favorite':favorite};
  factory Song.fromJson(Map<String,dynamic> x)=>Song(
    title:x['title']??'', lyrics:x['lyrics']??'', category:x['category']??'Masihi Geet',
    videoUrl:x['videoUrl']??'', favorite:x['favorite']??false);
}

class Store {
  static const key='christian_songs_v2';
  static Future<List<Song>> load() async {
    final p=await SharedPreferences.getInstance();
    final raw=p.getString(key);
    if(raw==null) return [];
    return (jsonDecode(raw) as List).map((e)=>Song.fromJson(e)).toList();
  }
  static Future<void> save(List<Song> songs) async {
    final p=await SharedPreferences.getInstance();
    await p.setString(key,jsonEncode(songs.map((e)=>e.toJson()).toList()));
  }
}

class ChristianApp extends StatelessWidget {
  const ChristianApp({super.key});
  @override Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false, title:'Christian Songs & Zaboor',
    theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.indigo),
    home:const Home());
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override State<Home> createState()=>_HomeState();
}
class _HomeState extends State<Home> {
  List<Song> songs=[]; bool loading=true; String q='';
  @override void initState(){super.initState();load();}
  Future<void> load() async {songs=await Store.load();setState(()=>loading=false);}
  Future<void> edit([Song? old]) async {
    final s=await Navigator.push<Song>(context,MaterialPageRoute(builder:(_)=>Edit(song:old)));
    if(s==null)return;
    setState(()=>old==null?songs.add(s):songs[songs.indexOf(old)]=s);
    await Store.save(songs);
  }
  Future<void> remove(Song s) async {
    final yes=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
      title:const Text('Delete / حذف کریں'),content:Text(s.title),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
      FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete'))]))??false;
    if(yes){setState(()=>songs.remove(s));await Store.save(songs);}
  }
  @override Widget build(BuildContext c){
    final shown=songs.where((s)=>('${s.title} ${s.category}').toLowerCase().contains(q.toLowerCase())).toList();
    return Scaffold(
      appBar:AppBar(title:const Text('✝️ Christian Songs & Zaboor')),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(),icon:const Icon(Icons.add),label:const Text('Add / شامل کریں')),
      body:loading?const Center(child:CircularProgressIndicator()):Column(children:[
        Padding(padding:const EdgeInsets.all(12),child:TextField(
          decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search / تلاش کریں',border:OutlineInputBorder()),
          onChanged:(v)=>setState(()=>q=v))),
        Expanded(child:shown.isEmpty?const Center(child:Text('No songs yet / ابھی کوئی گیت نہیں')):ListView.builder(
          itemCount:shown.length,itemBuilder:(_,i){final s=shown[i];return Card(
            margin:const EdgeInsets.symmetric(horizontal:12,vertical:5),
            child:ListTile(leading:CircleAvatar(child:Icon(s.category=='Zaboor'?Icons.menu_book:Icons.music_note)),
              title:Text(s.title),subtitle:Text(s.category),
              onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>SongPage(song:s,onChange:(){setState((){});Store.save(songs);}))),
              trailing:PopupMenuButton<String>(onSelected:(v){
                if(v=='edit')edit(s);
                if(v=='delete')remove(s);
                if(v=='fav'){setState(()=>s.favorite=!s.favorite);Store.save(songs);}
              },itemBuilder:(_)=>[
                PopupMenuItem(value:'fav',child:Text(s.favorite?'Remove Favorite':'Favorite / پسندیدہ')),
                const PopupMenuItem(value:'edit',child:Text('Edit / ترمیم')),
                const PopupMenuItem(value:'delete',child:Text('Delete / حذف'))])));}))
      ]));
  }
}

class Edit extends StatefulWidget {
  final Song? song; const Edit({super.key,this.song});
  @override State<Edit> createState()=>_EditState();
}
class _EditState extends State<Edit>{
  late TextEditingController t,l,v; String cat='Masihi Geet';
  @override void initState(){super.initState();final s=widget.song;t=TextEditingController(text:s?.title??'');l=TextEditingController(text:s?.lyrics??'');v=TextEditingController(text:s?.videoUrl??'');cat=s?.category??'Masihi Geet';}
  @override void dispose(){t.dispose();l.dispose();v.dispose();super.dispose();}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.song==null?'Add Song / نیا گیت':'Edit / ترمیم')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      TextField(controller:t,decoration:const InputDecoration(labelText:'Song Name / گیت کا نام',border:OutlineInputBorder())),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(value:cat,decoration:const InputDecoration(labelText:'Category / قسم',border:OutlineInputBorder()),
        items:const ['Masihi Geet','Zaboor','Worship','Christmas','Easter','Sunday School'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
        onChanged:(x)=>setState(()=>cat=x!)),
      const SizedBox(height:12),
      TextField(controller:l,minLines:10,maxLines:20,decoration:const InputDecoration(labelText:'Lyrics / گیت کے بول',alignLabelWithHint:true,border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:v,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'YouTube / Video Link',border:OutlineInputBorder())),
      const SizedBox(height:20),
      FilledButton.icon(onPressed:(){if(t.text.trim().isEmpty)return;Navigator.pop(c,Song(title:t.text.trim(),lyrics:l.text,category:cat,videoUrl:v.text.trim(),favorite:widget.song?.favorite??false));},icon:const Icon(Icons.save),label:const Text('Save / محفوظ کریں'))
    ]));
}

class SongPage extends StatelessWidget {
  final Song song; final VoidCallback onChange;
  const SongPage({super.key,required this.song,required this.onChange});
  Future<void> video(BuildContext c) async {
    if(song.videoUrl.trim().isEmpty){ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('Video link محفوظ نہیں ہے')));return;}
    final uri=Uri.tryParse(song.videoUrl.trim());
    if(uri!=null && await canLaunchUrl(uri)){await launchUrl(uri,mode:LaunchMode.externalApplication);}
    else if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('Video link درست نہیں ہے')));
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(leading:IconButton(tooltip:'Video / ویڈیو',icon:const Icon(Icons.play_circle_fill),onPressed:()=>video(c)),
      title:Text(song.title),actions:[IconButton(icon:Icon(song.favorite?Icons.favorite:Icons.favorite_border),onPressed:(){song.favorite=!song.favorite;onChange();})]),
    body:SingleChildScrollView(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Chip(label:Text(song.category)),const SizedBox(height:16),
      Text(song.lyrics,style:const TextStyle(fontSize:20,height:1.7)),
      const SizedBox(height:24),
      if(song.videoUrl.isNotEmpty)FilledButton.icon(onPressed:()=>video(c),icon:const Icon(Icons.play_arrow),label:const Text('Play Video / ویڈیو چلائیں'))
    ])));
}
