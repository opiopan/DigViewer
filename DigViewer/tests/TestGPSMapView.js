function Bridge() {
    this.onLoad = function (){
    };
    this.reflectGpsInfo = function (){
        testSetMarker();
    };
};

window.bridge = new Bridge();

function testSetKey(){
    var key = document.apikey.key.value;
    var object = document.getElementById("key_form");
    var parent = object.parentNode;
    parent.removeChild(object);
    setKey(key);
}

function testSetMarker(){
    var latitude = document.main.latitude.value;
    var longitude = document.main.longitude.value;
    var heading = document.main.heading.value;
    var focalLength = document.main.focal_length.value;
    var arrowColor = document.main.arrow_color.value;
    var fovColor = document.main.fov_color.value;
    
    var angle = null;
    var scale = null;
    if (heading){
        if (focalLength && focalLength > 0){
            angle = Math.atan(36 / 2 / focalLength);
            scale = 1 / Math.cos(angle);
            angle = angle * (180 / Math.PI);
        }
        heading *= 1;
    }else{
        heading = null;
    }
    setMarker(latitude, longitude, heading, angle, scale, fovColor, arrowColor);
}

function testResetMarker(){
    resetMarker();
}
