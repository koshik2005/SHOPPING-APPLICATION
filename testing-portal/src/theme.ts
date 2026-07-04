// @ts-nocheck
import { createTheme } from '@mui/material/styles';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#6366f1',
      light: '#818cf8',
      dark: '#4f46e5',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#06b6d4',
      light: '#22d3ee',
      dark: '#0891b2',
      contrastText: '#ffffff',
    },
    success: { main: '#10b981', light: '#34d399', dark: '#059669' },
    error:   { main: '#ef4444', light: '#f87171', dark: '#dc2626' },
    warning: { main: '#f59e0b', light: '#fbbf24', dark: '#d97706' },
    info:    { main: '#3b82f6', light: '#60a5fa', dark: '#2563eb' },
    background: {
      default: '#0a0f1e',
      paper:   '#111827',
    },
    text: {
      primary:   '#f9fafb',
      secondary: '#9ca3af',
      disabled:  '#4b5563',
    },
    divider: '#1f2937',
  },
  typography: {
    fontFamily: "'Inter', sans-serif",
    h1: { fontWeight: 800, letterSpacing: '-0.025em' },
    h2: { fontWeight: 700, letterSpacing: '-0.02em' },
    h3: { fontWeight: 700 },
    h4: { fontWeight: 600 },
    h5: { fontWeight: 600 },
    h6: { fontWeight: 600 },
    subtitle1: { fontWeight: 500, color: '#d1d5db' },
    subtitle2: { fontWeight: 500, color: '#9ca3af' },
    body1: { lineHeight: 1.6 },
    body2: { lineHeight: 1.5, color: '#d1d5db' },
    caption: { color: '#6b7280' },
  },
  shape: { borderRadius: 12 },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: { backgroundColor: '#0a0f1e' },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
          backgroundColor: '#111827',
          border: '1px solid #1f2937',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
          backgroundColor: '#111827',
          border: '1px solid #1f2937',
          transition: 'transform 0.2s, box-shadow 0.2s',
          '&:hover': {
            transform: 'translateY(-2px)',
            boxShadow: '0 8px 32px rgba(99,102,241,0.15)',
          },
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: { borderRadius: 8, textTransform: 'none', fontWeight: 600, letterSpacing: 0 },
        contained: {
          background: 'linear-gradient(135deg, #6366f1 0%, #4f46e5 100%)',
          boxShadow: '0 4px 16px rgba(99,102,241,0.3)',
          '&:hover': { boxShadow: '0 6px 24px rgba(99,102,241,0.45)' },
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: { fontWeight: 600, fontSize: '0.7rem', borderRadius: 6 },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        root: { borderColor: '#1f2937' },
        head: { fontWeight: 600, backgroundColor: '#0d1525', color: '#9ca3af', fontSize: '0.72rem', textTransform: 'uppercase', letterSpacing: '0.05em' },
      },
    },
    MuiTextField: {
      defaultProps: { size: 'small', variant: 'outlined' },
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: 8,
            '& fieldset': { borderColor: '#374151' },
            '&:hover fieldset': { borderColor: '#6366f1' },
            '&.Mui-focused fieldset': { borderColor: '#6366f1' },
          },
        },
      },
    },
    MuiTooltip: {
      styleOverrides: {
        tooltip: { backgroundColor: '#1f2937', border: '1px solid #374151', fontSize: '0.75rem' },
      },
    },
    MuiAlert: {
      styleOverrides: {
        root: { borderRadius: 10 },
      },
    },
    MuiLinearProgress: {
      styleOverrides: {
        root: { borderRadius: 4, backgroundColor: '#1f2937' },
        bar: { background: 'linear-gradient(90deg, #6366f1, #06b6d4)' },
      },
    },
  },
});

export default theme;
