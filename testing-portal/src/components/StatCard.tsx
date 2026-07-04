// @ts-nocheck
import React from 'react';
import { Card, CardContent, Box, Typography, Skeleton } from '@mui/material';
import { TrendingUp, TrendingDown } from '@mui/icons-material';

interface StatCardProps {
  label: string;
  value: number | string | undefined;
  icon: React.ReactNode;
  color: string;
  prefix?: string;
  suffix?: string;
  trend?: number;
  loading?: boolean;
  sub?: string;
}

export default function StatCard({ label, value, icon, color, prefix = '', suffix = '', trend, loading, sub }: StatCardProps) {
  return (
    <Card sx={{ position: 'relative', overflow: 'hidden' }}>
      {/* Gradient stripe */}
      <Box
        sx={{
          position: 'absolute', top: 0, left: 0, right: 0, height: 3,
          background: `linear-gradient(90deg, ${color}, transparent)`,
        }}
      />
      <CardContent sx={{ p: 2.5 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <Box>
            <Typography sx={{ fontSize: '0.72rem', fontWeight: 600, color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.06em', mb: 0.8 }}>
              {label}
            </Typography>
            {loading ? (
              <Skeleton width={80} height={36} sx={{ bgcolor: '#1f2937' }} />
            ) : (
              <Typography variant="h4" sx={{ fontWeight: 800, color: '#f9fafb', lineHeight: 1, letterSpacing: '-0.02em' }}>
                {prefix}{typeof value === 'number' ? value.toLocaleString() : (value ?? '—')}{suffix}
              </Typography>
            )}
            {sub && !loading && (
              <Typography sx={{ fontSize: '0.72rem', color: '#6b7280', mt: 0.5 }}>{sub}</Typography>
            )}
            {trend !== undefined && !loading && (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.8 }}>
                {trend >= 0 ? (
                  <TrendingUp sx={{ fontSize: 14, color: '#10b981' }} />
                ) : (
                  <TrendingDown sx={{ fontSize: 14, color: '#ef4444' }} />
                )}
                <Typography sx={{ fontSize: '0.7rem', color: trend >= 0 ? '#10b981' : '#ef4444', fontWeight: 600 }}>
                  {Math.abs(trend)}%
                </Typography>
              </Box>
            )}
          </Box>
          <Box
            sx={{
              width: 46, height: 46, borderRadius: 2.5,
              bgcolor: `${color}1a`, display: 'flex', alignItems: 'center', justifyContent: 'center',
              '& .MuiSvgIcon-root': { color, fontSize: 22 },
            }}
          >
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}
