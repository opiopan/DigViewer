//
//  GPSMapView.js
//  DigViewer
//
//  Created by opiopan on 2014/03/30.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

var map = null;
var imageLocation = null;
var zoomLevel = 10;
var imageVector = null;
var imageHeading = null;
var FOVangle = -1;
var FOVscale = 0;
var FOVgrade = 30;
var FOVgradeMax = FOVgrade;
var LastFOVgrade = FOVgrade;
var FOVmarker = [];
var defLatLng = null;
var marker = null;
var fovColor = null;
var arrowColor = null;
var isIncompleteArrow = false;

var mapType = 0;
var enableStreetView = true;

var msgLoading = "msgLoading";
var msgNoKey = "msgNoKey";
var msgInvalidKey = "msgInvalidKey";
var msgSpecifyKeyButton = "msgSpecifyKeyButton"

window.onload = function (){
    window.digViewerBridge.onLoad();
};

function setKey(key){
    var primaryMsg = document.getElementById("primary_msg");
    var secondaryMsg = document.getElementById("secondary_msg");
    primaryMsg.firstChild.nodeValue = msgLoading;
    if (key === ""){
        secondaryMsg.firstChild.nodeValue = msgNoKey;
        var object = document.getElementById("map_canvas");
        var parent = object.parentNode;
        parent.removeChild(object);
    }else{
        secondaryMsg.firstChild.nodeValue = msgInvalidKey;
        var script = document.createElement("script");
        script.type = "text/javascript";
        script.src = "http://maps.googleapis.com/maps/api/js?key=";
        script.src += key;
        script.src += "&libraries=geometry,drawing&sensor=false&callback=initialize";
        document.body.appendChild(script);
    }
    document.control.key.value = msgSpecifyKeyButton;
}

function initialize() {
    defLatLng = new google.maps.LatLng(0, 0);

    var i;
    for (i = 0; i < FOVgrade; i++){
        FOVmarker.push(null);
    }

    var convertedMapType;
    switch (mapType){
        case 0:
            convertedMapType = google.maps.MapTypeId.ROADMAP;
            break;
        case 1:
            convertedMapType = google.maps.MapTypeId.TERRAIN;
            break;
        default:
            convertedMapType = google.maps.MapTypeId.HYBRID;
    }
    
    var mapOptions = {
        center: defLatLng,
        zoom: 1,
        mapTypeId: convertedMapType,
        panControl: false,
        zoomControl: true,
        mapTypeControl: true,
        scaleControl: true,
        streetViewControl: enableStreetView,
        overviewMapControl: true
    };
    if (imageLocation){
        mapOptions.center = imageLocation;
        mapOptions.zoom = zoomLevel;
    }
    map = new google.maps.Map(document.getElementById("map_canvas"),mapOptions);
    google.maps.event.addListener(map, "bounds_changed", function(){if (isIncompleteArrow) setHeading();});
    google.maps.event.addListener(map, "zoom_changed", function(){setHeading();});
    window.digViewerBridge.reflectGpsInfo();
}

function setMarker(latitude, longitude, heading, angle, scale, fovc, arrc, fovg) {
    if (map){
        if (!imageLocation){
            map.setZoom(zoomLevel);
        }
        imageLocation = new google.maps.LatLng(latitude, longitude);
        if (marker){
            marker.setMap(null);
        }
        marker = new google.maps.Marker({
                                        position: imageLocation,
                                        map: map
                                        });
        map.setCenter(imageLocation);
        imageHeading = heading;
        FOVangle = angle;
        FOVscale = scale;
        if (fovc){
            fovColor = fovc;
        }else{
            fovColor = "#000000";
        }
        if (arrc){
            arrowColor = arrc;
        }else{
            arrowColor = "#000000";
        }
        FOVgrade = fovg;
        setHeading();
    }else{
        imageLocation = new google.maps.LatLng(latitude, longitude);
        imageHeading = heading;
    }
}

function resetMarker(moveToHome) {
    if (imageLocation){
        if (map){
            zoomLevel = map.getZoom();
        }
        if (moveToHome){
            imageLocation = null;
        }
    }
    if (marker){
        marker.setMap(null);
        marker = null;
    }
    imageHeading = null;
    FOVangle = -1;
    FOVscale = 0;
    setHeading();
    if (map && moveToHome){
        map.setZoom(1);
        map.setCenter(defLatLng);
    }
}

function setHeading() {
    isIncompleteArrow = false;
    if (imageVector){
        imageVector.setMap(null);
        imageVector = null;
    }
    var i;
    for (i = 0; i < LastFOVgrade; i++){
        if (FOVmarker[i]){
            FOVmarker[i].setMap(null);
            FOVmarker[i] = null;
        }
    }
    if (imageHeading || imageHeading == 0){
        var vecLength = headingLength();
        var to = google.maps.geometry.spherical.computeOffset(imageLocation, vecLength, imageHeading);
        if (FOVangle > 0){
            if (FOVgrade > FOVgradeMax){
                var i;
                for (i = 0; i < FOVgradeMax - FOVgrade; i++){
                    FOVmarker.push(null);
                }
                FOVgradeMax = FOVgrade;
            }
            
            var color = fovColor;
            var opacity = 0.6 / FOVgrade;
            var divLength = vecLength * FOVscale / FOVgrade * 2;
            var i;
            for (i = 0; i < FOVgrade; i++){
                var left = google.maps.geometry.spherical.computeOffset(imageLocation,
                                                                        divLength * (i + 1), imageHeading - FOVangle);
                var right = google.maps.geometry.spherical.computeOffset(imageLocation,
                                                                        divLength * (i + 1), imageHeading + FOVangle);
                var fovOpt = {
                    path: [imageLocation, left, right],
                    fillOpacity: opacity,
                    fillColor: color,
                    strokeColor: color,
                    strokeOpacity: 0,
                    strokeWeight: 1
                };
                FOVmarker[i] = new google.maps.Polygon(fovOpt);
                FOVmarker[i].setMap(map);
            }
            LastFOVgrade = FOVgrade;
        }
        var color = arrowColor;
        var opacity = 0.7;
        var headArrow = {
            path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW,
            fillOpacity: opacity,
            fillColor: color,
            strokeColor: color,
            strokeOpacity: opacity
        };
        var icon_symbol =  [{icon: headArrow, offset: '100%'}];
        var vectorOpt = {
            path: [imageLocation, to],
            icons: icon_symbol,
            strokeColor: color,
            strokeOpacity: opacity,
            strokeWeight: 3
        };
        imageVector = new google.maps.Polyline(vectorOpt);
        imageVector.setMap(map);
    }
}

function headingLength() {
    var bounds = map.getBounds();
    if (bounds){
        var northEast = bounds.getNorthEast();
        var southWest = bounds.getSouthWest();
        var northWest = new google.maps.LatLng(northEast.lat(), southWest.lng());
        var width = google.maps.geometry.spherical.computeDistanceBetween(northEast, northWest);
        var height = google.maps.geometry.spherical.computeDistanceBetween(southWest, northWest);
        var ratio = 0.4;
        if (height > width){
            return width * ratio;
        }else{
            return height * ratio;
        }
    }else{
        isIncompleteArrow = true;
        return 0;
    }
}

function specifyKey() {
    window.digViewerBridge.onSpecifyKey();
}

function setStreetViewControll(state) {
    enableStreetView = state;
    if (map){
        var mapOptions = {
            streetViewControl: enableStreetView
        };
        map.setOptions(mapOptions);
    }
}