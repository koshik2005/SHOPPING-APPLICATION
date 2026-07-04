// @ts-nocheck
import React, { useEffect, useRef } from 'react';
import { Box } from '@mui/material';

import L from 'leaflet';

// Fix default marker icon
if (typeof window !== 'undefined') {
  delete (L.Icon.Default.prototype as any)._getIconUrl;
  L.Icon.Default.mergeOptions({
    iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  });
}


interface Marker {
  lat: number;
  lng: number;
  label?: string;
  draggable?: boolean;
  onDrag?: (lat: number, lng: number) => void;
  color?: string;
}

interface Circle {
  lat: number;
  lng: number;
  radiusKm: number;
  color?: string;
}

interface MapViewProps {
  center?: [number, number];
  zoom?: number;
  markers?: Marker[];
  circles?: Circle[];
  height?: number | string;
}

export default function MapView({ center = [37.7749, -122.4194], zoom = 13, markers = [], circles = [], height = 400 }: MapViewProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<any>(null);
  const markersRef = useRef<any[]>([]);
  const circlesRef = useRef<any[]>([]);

  useEffect(() => {
    if (!L || !containerRef.current || mapRef.current) return;

    mapRef.current = L.map(containerRef.current, {
      center,
      zoom,
      zoomControl: true,
    });

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(mapRef.current);

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (!mapRef.current || !L) return;

    // Clear old markers
    markersRef.current.forEach(m => m.remove());
    markersRef.current = [];

    markers.forEach(m => {
      const icon = L.divIcon({
        html: `<div style="background:${m.color ?? '#6366f1'};width:14px;height:14px;border-radius:50%;border:2px solid white;box-shadow:0 2px 8px rgba(0,0,0,0.4);"></div>`,
        className: '',
        iconSize: [14, 14],
        iconAnchor: [7, 7],
      });
      const marker = L.marker([m.lat, m.lng], { icon, draggable: m.draggable ?? false });
      if (m.label) marker.bindPopup(m.label);
      if (m.draggable && m.onDrag) {
        marker.on('dragend', (e: any) => {
          const pos = e.target.getLatLng();
          m.onDrag!(pos.lat, pos.lng);
        });
      }
      marker.addTo(mapRef.current);
      markersRef.current.push(marker);
    });
  }, [markers]);

  useEffect(() => {
    if (!mapRef.current || !L) return;

    circlesRef.current.forEach(c => c.remove());
    circlesRef.current = [];

    circles.forEach(c => {
      const circle = L.circle([c.lat, c.lng], {
        radius: c.radiusKm * 1000,
        color: c.color ?? '#6366f1',
        fillColor: c.color ?? '#6366f1',
        fillOpacity: 0.08,
        weight: 2,
      });
      circle.addTo(mapRef.current);
      circlesRef.current.push(circle);
    });
  }, [circles]);

  return (
    <Box
      ref={containerRef}
      sx={{
        height,
        borderRadius: 2,
        overflow: 'hidden',
        border: '1px solid #1f2937',
        '& .leaflet-container': { bgcolor: '#1a1f35' },
      }}
    />
  );
}
