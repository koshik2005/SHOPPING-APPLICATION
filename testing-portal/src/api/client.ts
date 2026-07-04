// @ts-nocheck
import axios from 'axios';

const api = axios.create({
  baseURL: '',  // Vite proxy handles /api → :8080
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.response.use(
  res => res,
  err => {
    console.error('[API Error]', err.response?.status, err.config?.url, err.response?.data);
    return Promise.reject(err);
  }
);

export default api;
