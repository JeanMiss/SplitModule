package
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	public class EgretTexureSplit extends Sprite
	{
		private var _tf:TextField;
		private var _btn:TextField;
		private var fileUrl:String;
		private var pngdic:Dictionary = new Dictionary;
		private var jsondic:Dictionary = new Dictionary;
		public function EgretTexureSplit()
		{
			super();
			
			_tf = new TextField();
			_tf.width = 300;
			_tf.height = 300;
			_tf.border = true;
			_tf.text = "拖入要拆分的文件到这里\njson文件与png文件名称相同";
			this.addChild(_tf);
			
			_btn = new TextField();
			_btn.width = 40;
			_btn.height = 30;
			_btn.background = true;
			_btn.backgroundColor = 0xcccc00;
			_btn.text = "导出";
			_btn.x = 350;
			_btn.y = 10;
			this.addChild(_btn);
			_btn.addEventListener(MouseEvent.CLICK,onBtnClick);
			
			_tf.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER,onDragEnter);
			_tf.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,onDragDrop);
			
		}
		private function onDragEnter(e:NativeDragEvent):void{
			var clip:Clipboard = e.clipboard;
			if(clip.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)){
				NativeDragManager.acceptDragDrop(_tf);
			}
		}
		private function onDragDrop(e:NativeDragEvent):void{
			var clip:Clipboard = e.clipboard;
			var formats:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			for(var i:int=0;i<formats.length;i++){
				var file:File = formats[i];
				var ext:Array = file.name.split(".");
				var tname:String = String(ext[0]).slice(0,-3);
				_tf.text += "\n"+file.name;
				if(ext[1]=="png"){
					if(pngdic[tname]==null){
						pngdic[tname] = file.nativePath;
					}
				}else if(ext[1]=="json" || ext[1]=="fnt"){
					if(jsondic[tname]==null){
						jsondic[tname]=file.nativePath;
					}
				}
			}
			
		}

		private function onBtnClick(e:MouseEvent):void{
			if(fileUrl==null){
				var file:File = new File();
				file.addEventListener(Event.SELECT, dirSelected);
				file.browseForDirectory("Select a directory");
				function dirSelected(e:Event):void {
					fileUrl = file.nativePath;
					getNext();
				}
			}else{
				getNext();
			}
			
		}
		private function getNext():void{
			for (var key:String in pngdic){
				if(jsondic[key]==null){
					continue;
				}
				LoadMgr.ins.load(key,[{"url":pngdic[key],"type":"bmp"},{"url":jsondic[key],"type":"json"}],onComplete);
			}
		}
		private function onComplete(key:String):void{
			var arr:Array = LoadMgr.ins.dataRes[key];
			delete pngdic[key];
			delete jsondic[key];
			splitImage(key,arr);
			//
			this.getNext();
		}
		private function splitImage(key:String,arr:Array):void{
			var jsonObj:Object = arr[0];
			var orginBd:BitmapData = arr[1];
			if(jsonObj.hasOwnProperty("mc")){
				parseMc(key,jsonObj,orginBd);
			}else if(jsonObj.hasOwnProperty("file")){
				parseDigital(key,jsonObj,orginBd);
			}
			
		}
		private function parseMc(key:String,jsonObj:Object,orginBd:BitmapData):void{
			var res:Object = jsonObj["res"];
			var isRole:Boolean = isRoleAni(jsonObj);
			for(var s:String in jsonObj["mc"]){
				var frames:Array = jsonObj["mc"][s].frames;
				//var wh:Array = getWH(frames,res);
				var j:int=0;
				for(var i:int=0;i<frames.length;i++){
					var obj:Object = res[frames[i].res];
					if(obj.w==1 && obj.h==1){
						continue;
					}
					
//					var bd:BitmapData = new BitmapData(640,640,true,0x0);
//					bd.copyPixels(orginBd,new Rectangle(obj.x,obj.y,obj.w,obj.h),new Point(frames[i].x,frames[i].y));
//					var bd2:BitmapData = new BitmapData(wh[0],wh[1],true,0x0);
//					bd2.copyPixels(bd,new Rectangle(bd.width-wh[0],bd.height-wh[1],wh[0],wh[1]),new Point(0,0));
					
					var bd:BitmapData = new BitmapData(obj.w,obj.h,true,0x0);
					bd.copyPixels(orginBd,new Rectangle(obj.x,obj.y,obj.w,obj.h),new Point(0,0));
					var pngByte:ByteArray = PNGEncoder.encode(bd);
					
					saveFile(fileUrl+"/"+key+"/"+s+"_"+j+".png",pngByte);
//					if(isRole){
//						saveFile("splitImg/"+key+"/"+s+"/"+j+".png",pngByte);
//					}else{ 
//						saveFile("splitImg/"+key+"/"+j+".png",pngByte);
//					}
					j++;
				} 
			}
		}
		private function getWH(frames:Array,res:Object):Array{
			var maxw:int;
			var maxh:int;
			for(var i:int=0;i<frames.length;i++){
				var obj:Object = res[frames[i].res];
				maxw = (obj.w>maxw?obj.w:maxw);
				maxh = (obj.h>maxh?obj.h:maxh);
			}
			return [maxw+2,maxh+2];
		}
		private function parseDigital(key:String,jsonObj:Object,orginBd:BitmapData):void{
			var frames:Object = jsonObj["frames"];
			for(var i:String in frames){
				var obj:Object = frames[i];
				var bd:BitmapData = new BitmapData(obj.w,obj.h);
				bd.copyPixels(orginBd,new Rectangle(obj.x,obj.y,obj.w,obj.h),new Point(0,0));
				var pngByte:ByteArray = PNGEncoder.encode(bd);
				saveFile(fileUrl+"/"+key+"/"+i+".png",pngByte);
			}
		}
		private function isRoleAni(json:Object):Boolean{
			for (var key:String in json){
				if(key=="mc"){
					var j:int = 0;
					for (var key1:String in json[key]){
						j++;
					}
					if(j>1){
						return true
					}
				}
			}
			return null;
		}
		private function saveFile(url:String,byte:ByteArray):void{
			var fl:File = File.desktopDirectory.resolvePath(url);
			var fs:FileStream = new FileStream();
			try{
				fs.open(fl,FileMode.WRITE);
				fs.writeBytes(byte);
				fs.close();
			}catch(e:Error){
				trace(e.message);
			}
		}
	}
}