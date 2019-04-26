package
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;

	public class LoadMgr
	{
		private static var _ins:LoadMgr;
		public static function get ins():LoadMgr
		{
			return _ins||=new LoadMgr;
		}
		
		private var _load:URLLoader;
		private var _loadPng:Loader;
		private var taskObj:Object={};
		private var compFunc:Function;
		private var isLoading:Boolean;
		private var curKey:String;
		public var dataRes:Object={};
		public function LoadMgr()
		{
		}
		public function load(key:String,obj:Array,compFunc:Function):void{
			
			this.compFunc = compFunc;
			taskObj[key] = obj;
			
			if(!isLoading){
				getNext();
			}
		}
		private function getNext():void{
			var obj:Array = null;
			for (var key:String in taskObj){
				obj = taskObj[key];
				curKey = key;
				break;
			}
			delete taskObj[key];
			isLoading = true;
			nextLoad(key,obj[0]["url"],obj[0]["type"]);
			nextLoad(key,obj[1]["url"],obj[1]["type"]);
		}
		private function nextLoad(key:String,url:String,type:String):void{
			if(dataRes[key]==null){
				dataRes[key] = [];
			}
			if(type=="bmp"){
				addLoadPng(url);
			}else{
				addLoadText(url);
			}
		}
		private function addLoadText(url:String):void{
			if(_load==null){
				_load = new URLLoader();
				_load.addEventListener(Event.COMPLETE,onLoadTextComplete);
			}
			_load.dataFormat = URLLoaderDataFormat.TEXT;
			_load.load(new URLRequest(url));
		}
		private function onLoadTextComplete(e:Event):void{
			
			dataRes[curKey][0] = JSON.parse(e.target.data);
			if(isLoadComplete()){
				if(compFunc!=null){
					this.compFunc(curKey);
				}
				
			}
		}
		private function addLoadPng(url:String):void{
			if(_loadPng==null){
				_loadPng = new Loader();
				_loadPng.contentLoaderInfo.addEventListener(Event.COMPLETE,onLoadPngComplete);
			}
			_loadPng.load(new URLRequest(url));
		}
		private function onLoadPngComplete(e:Event):void{
			var d:Bitmap = (e.target as LoaderInfo).content as Bitmap;
			dataRes[curKey][1] = d.bitmapData; 
			if(isLoadComplete()){
				if(compFunc!=null){
					this.compFunc(curKey);
				}
				
			}
		}
		private function isLoadComplete():Boolean{
			var arr:Array = dataRes[curKey];
			if(arr.length==2){
				isLoading = false;
			}
			return !isLoading;
		}
	}
}