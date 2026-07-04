// @ts-nocheck
import axios from 'axios';

const client = axios.create({
  baseURL: '',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor to attach Authorization Bearer token
client.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    const sessionId = localStorage.getItem('sessionId');
    if (sessionId) {
      config.headers['X-Session-ID'] = sessionId;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Interceptor to handle token refresh on 401 Unauthorized
let isRefreshing = false;
let failedQueue: any[] = [];

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve(token);
    }
  });
  failedQueue = [];
};

client.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        })
          .then((token) => {
            originalRequest.headers['Authorization'] = `Bearer ${token}`;
            return client(originalRequest);
          })
          .catch((err) => Promise.reject(err));
      }

      originalRequest._retry = true;
      isRefreshing = true;

      const refreshToken = localStorage.getItem('refreshToken');
      if (!refreshToken) {
        isRefreshing = false;
        handleLogout();
        return Promise.reject(error);
      }

      try {
        const refreshResponse = await axios.post('/api/v1/auth/refresh', {
          refreshToken,
        });

        const authData = refreshResponse.data?.data;
        if (authData && authData.accessToken) {
          localStorage.setItem('accessToken', authData.accessToken);
          if (authData.refreshToken) {
            localStorage.setItem('refreshToken', authData.refreshToken);
          }
          client.defaults.headers.common['Authorization'] = `Bearer ${authData.accessToken}`;
          originalRequest.headers['Authorization'] = `Bearer ${authData.accessToken}`;

          processQueue(null, authData.accessToken);
          isRefreshing = false;
          return client(originalRequest);
        } else {
          throw new Error('Refresh response does not contain accessToken');
        }
      } catch (refreshError) {
        processQueue(refreshError, null);
        isRefreshing = false;
        handleLogout();
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);

function handleLogout() {
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
  localStorage.removeItem('sessionId');
  localStorage.removeItem('user');
  if (window.location.pathname !== '/login') {
    window.location.href = '/login';
  }
}

export default client;
