import 'package:flutter/material.dart';
import 'constants.dart';

class CopyrightFooter extends StatelessWidget {
  const CopyrightFooter({super.key});
  @override Widget build(BuildContext context)=>const Padding(padding:EdgeInsets.symmetric(vertical:24),child:Column(children:[Text(copyright1,textAlign:TextAlign.center,style:TextStyle(fontSize:12)),Text(copyright2,textAlign:TextAlign.center,style:TextStyle(fontSize:11))]));
}
