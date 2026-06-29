package com.hyperlocal.integration.maps;

import org.springframework.stereotype.Component;

@Component
public class GoogleMapsClient {
    public double getDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
        // Concrete adapter invoking external Google Distance Matrix APIs
        return 0.0;
    }
}
