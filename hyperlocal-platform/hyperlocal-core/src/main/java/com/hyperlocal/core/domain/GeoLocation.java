package com.hyperlocal.core.domain;

import lombok.Value;

@Value
public class GeoLocation {
    Coordinates coordinates;
    String name;

    public double distanceTo(GeoLocation other) {
        if (other == null) {
            throw new IllegalArgumentException("Target location cannot be null");
        }
        
        final double earthRadius = 6371.0; // Kilometers
        
        double lat1 = Math.toRadians(this.coordinates.getLatitude());
        double lon1 = Math.toRadians(this.coordinates.getLongitude());
        double lat2 = Math.toRadians(other.getCoordinates().getLatitude());
        double lon2 = Math.toRadians(other.getCoordinates().getLongitude());
        
        double dLat = lat2 - lat1;
        double dLon = lon2 - lon1;
        
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(lat1) * Math.cos(lat2) *
                   Math.sin(dLon / 2) * Math.sin(dLon / 2);
                   
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        return earthRadius * c;
    }
}
