# React Frontend with Thecore — Reference Guide

This document describes how to build a React frontend that connects to a Thecore backend using the **thecore-auth** npm package.

**thecore-auth** provides a complete authentication and routing layer for React applications that consume Thecore REST APIs, JWT tokens, ActionCable WebSocket channels, and admin-protected resources.

- **Package repository:** [github.com/SantiGalvan/thecore-auth](https://github.com/SantiGalvan/thecore-auth)
- **License:** MIT
- **React version required:** 19.0.0+
- **Router:** React Router 7.1.3

---

## Prerequisites

- A running Thecore backend (see [GUIDE.md](GUIDE.md) and [WALKTHROUGH.md](WALKTHROUGH.md))
- Node.js 18+ and npm
- Familiarity with React 18/19 and React Router v6/v7

---

## Installation

```bash
npm install thecore-auth
```

Peer dependencies that will be installed automatically:

| Package | Purpose |
|---|---|
| `axios` | HTTP client for Thecore REST API calls |
| `jwt-decode` | Decodes JWT tokens without verification |
| `react-router-dom` | Client-side routing |

---

## Configuration File

Before anything else, create a `config.json` file in the `public/` folder of your React project. This file is fetched at runtime by `ConfigProvider` and drives every aspect of the library.

```json
{
  "baseUri": "https://your-thecore-backend.example.com",
  "endpoints": {
    "login": "/api/v2/authenticate",
    "heartbeat": "/api/v2/heartbeat",
    "user": "/api/v2/users"
  },
  "routes": {
    "firstPrivatePath": "/dashboard/",
    "loginPath": "/"
  },
  "session": {
    "infiniteSession": false,
    "sessionTimeoutInMinutes": 31,
    "tokenExpiryDeductionInSeconds": 30
  },
  "app": {
    "name": "MyApp",
    "version": "1.0.0",
    "debug": false
  },
  "autoLogin": false,
  "messages": {
    "unauthorized": "Non sei autorizzato",
    "notFound": "Risorsa non trovata",
    "genericError": "Errore imprevisto (status: {{status}})"
  }
}
```

Key fields:

| Field | Description |
|---|---|
| `baseUri` | Base URL of the Thecore backend. All API calls are relative to this. |
| `endpoints.login` | JWT authentication endpoint (`POST`) |
| `endpoints.heartbeat` | Token refresh endpoint for infinite sessions |
| `endpoints.user` | User detail endpoint |
| `routes.firstPrivatePath` | Where to redirect after successful login (e.g. `/dashboard/`) |
| `routes.loginPath` | The public login route (usually `/`) |
| `session.infiniteSession` | If `true`, the token is periodically refreshed via heartbeat |
| `session.sessionTimeoutInMinutes` | Idle timeout before automatic logout |
| `session.tokenExpiryDeductionInSeconds` | Buffer subtracted from JWT expiry to trigger refresh early |
| `autoLogin` | If `true`, the app attempts silent login on page load using stored credentials |

---

## Provider Architecture

The library is built around React Context. Every feature (auth state, config, alerts, modals, routing, login form) is a separate provider.

### Minimal setup — `main.jsx`

```jsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'thecore-auth';
import {
  LoadingProvider,
  ConfigProvider,
  AlertProvider,
  AuthProvider,
  LoginFormProvider,
  ModalProvider,
} from 'thecore-auth';
import App from './App';
import 'thecore-auth/dist/thecore-auth.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <LoadingProvider>
        <ConfigProvider>
          <AlertProvider>
            <AuthProvider>
              <LoginFormProvider>
                <ModalProvider>
                  <App />
                </ModalProvider>
              </LoginFormProvider>
            </AuthProvider>
          </AlertProvider>
        </ConfigProvider>
      </LoadingProvider>
    </BrowserRouter>
  </React.StrictMode>
);
```

**Provider order matters.** `ConfigProvider` must wrap `AuthProvider` because auth behaviour reads configuration. `AlertProvider` must wrap `AuthProvider` because auth functions trigger alerts.

### `App.jsx`

```jsx
import { RouteProvider, PackageRoutes } from 'thecore-auth';

export default function App() {
  return (
    <RouteProvider>
      <PackageRoutes />
    </RouteProvider>
  );
}
```

---

## Routing — `PackageRoutes`

`PackageRoutes` is the core routing component. It separates public routes (accessible without login) from private routes (wrapped by `AuthPage` authentication guard).

### Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `logo` | `ReactElement` | `null` | Logo shown on the login page |
| `favicon` | `string` | `null` | Path to favicon image |
| `headerComponent` | `ReactElement` | `null` | Custom header rendered in `DefaultLayout` |
| `footerComponent` | `ReactElement` | `null` | Custom footer rendered in `DefaultLayout` |
| `showHeaderOnLogin` | `boolean` | `false` | Whether to show the header on the login page |
| `disableLayout` | `boolean` | `false` | Disable `DefaultLayout` entirely |
| `customLayout` | `ReactElement` | `null` | Replace `DefaultLayout` with a custom layout |
| `privateProvider` | `ReactElement` | `null` | Extra context provider wrapping all private routes |
| `customProvider` | `ReactElement` | `null` | Additional provider inside the private route tree |

### Example — full `App.jsx`

```jsx
import { RouteProvider, PackageRoutes } from 'thecore-auth';
import MyHeader from './components/MyHeader';
import MyFooter from './components/MyFooter';
import MyLogo from './assets/MyLogo.svg';

export default function App() {
  return (
    <RouteProvider>
      <PackageRoutes
        logo={<img src={MyLogo} alt="Logo" />}
        headerComponent={<MyHeader />}
        footerComponent={<MyFooter />}
        showHeaderOnLogin={false}
      />
    </RouteProvider>
  );
}
```

### Adding application routes

Routes are injected via `RouteContext`. Use the `useRoutesInjection` hook (or the `RouteProvider` value) to register custom public and private routes dynamically. In practice, you define routes as children of either the public or private route groups in the context:

```jsx
import { useRoutesInjection, Route } from 'thecore-auth';

// Inside a component that is a child of RouteProvider:
const { addPrivateRoute, addPublicRoute } = useRoutesInjection();
```

---

## Authentication

### How it works with Thecore

1. The user submits credentials in the `Login` page.
2. `AuthContext` posts to `config.endpoints.login` via Axios.
3. Thecore returns a JWT token.
4. The token is stored in `localStorage` and attached to every subsequent request as `Authorization: Bearer <token>`.
5. On each successful response, Thecore issues a refreshed token (sliding expiry). The Axios response interceptor picks this up automatically.
6. If `infiniteSession` is enabled, a periodic `heartbeat` call keeps the session alive indefinitely.
7. On 401 responses, stored credentials are cleared and the user is redirected to login.

### `useAuth` hook

```jsx
import { useAuth } from 'thecore-auth';

function MyComponent() {
  const { isAuthenticated, login, logout, token } = useAuth();

  return isAuthenticated
    ? <button onClick={logout}>Logout</button>
    : <span>Not logged in</span>;
}
```

Available values from `useAuth`:

| Value | Type | Description |
|---|---|---|
| `isAuthenticated` | `boolean \| null` | `null` while loading, `true`/`false` after check |
| `token` | `string \| null` | Current JWT token |
| `login(credentials)` | `function` | Authenticate with `{ email, password }` |
| `logout()` | `function` | Clear session and redirect to login |
| `fetchHeartbeat()` | `function` | Manually trigger a token refresh |
| `checkTokenValidity()` | `function` | Returns `true` if stored token is still valid |

### Session management

Two session modes are available via `config.json`:

**Single-token mode** (`infiniteSession: false`)
The JWT expires after the time encoded in it, minus `tokenExpiryDeductionInSeconds`. When it expires, the user is logged out.

**Infinite session mode** (`infiniteSession: true`)
A periodic call to `endpoints.heartbeat` refreshes the token before it expires, keeping the session alive as long as the browser tab is open.

---

## HTTP Client — `axiosInstance`

The library exports a pre-configured Axios instance that:

- Reads `baseUri` from `config.json` for the base URL
- Injects the JWT token from `localStorage` into every request as `Authorization: Bearer <token>`
- Handles 401 responses by clearing credentials and calling `onUnauthorized`
- Handles 404 responses via `onNotFound`
- Handles all other errors via `onGenericError`

### Usage

```jsx
import { fetchAxiosConfig, useAlert } from 'thecore-auth';
import { useNavigate } from 'thecore-auth';

function useApi() {
  const { activeAlert } = useAlert();
  const navigate = useNavigate();

  const api = fetchAxiosConfig(
    (msg) => activeAlert('danger', msg),         // onUnauthorized
    () => navigate('/not-found'),                // onNotFound
    (msg) => activeAlert('warning', msg)         // onGenericError
  );

  return api;
}
```

Because `fetchAxiosConfig` is a singleton, it is safe to call it multiple times — the same instance is returned after the first call.

### Making API calls

```jsx
import { fetchAxiosConfig } from 'thecore-auth';

const api = fetchAxiosConfig(onUnauthorized, onNotFound, onError);

// GET list
const { data } = await api.get('/api/v2/vehicles');

// GET with Ransack filters
const { data } = await api.get('/api/v2/vehicles', {
  params: { 'q[name_cont]': 'truck', per_page: 25, page: 1 }
});

// POST
const { data } = await api.post('/api/v2/vehicles', { vehicle: { name: 'Truck A' } });

// PUT
await api.put(`/api/v2/vehicles/${id}`, { vehicle: { name: 'Truck B' } });

// DELETE
await api.delete(`/api/v2/vehicles/${id}`);
```

See [REST_API.md](REST_API.md) for full details on Thecore's endpoint conventions, Ransack search predicates, and pagination parameters.

---

## Middlewares (Route Guards)

### `AuthPage` — protect private routes

`AuthPage` is used internally by `PackageRoutes` to wrap all private routes. You do not normally use it directly. It checks `isAuthenticated`:

- `null` → renders nothing (loading)
- `true` → renders `<Outlet />` (child routes)
- `false` → redirects to `loginPath` with a "not authorized" alert

### `AuthAdmin` — restrict to admin users

Wrap specific routes in `AuthAdmin` to restrict them to users with `user.admin === true`:

```jsx
import { AuthAdmin, Route, Routes } from 'thecore-auth';
import AdminDashboard from './pages/AdminDashboard';

// Inside your route tree:
<Route element={<AuthAdmin />}>
  <Route path="/admin" element={<AdminDashboard />} />
</Route>
```

If a non-admin user navigates to an `AuthAdmin`-protected route, they are redirected to their previous location (or `/`) and shown an alert.

---

## Alert System

### `useAlert` hook

```jsx
import { useAlert } from 'thecore-auth';

function MyComponent() {
  const { activeAlert, closeAlert } = useAlert();

  return (
    <button onClick={() => activeAlert('success', 'Saved successfully!')}>
      Save
    </button>
  );
}
```

Alert types:

| Type | Use case |
|---|---|
| `success` | Successful operation |
| `danger` | Error or unauthorized action |
| `warning` | Non-critical problem |
| `info` | Informational message |

On mobile and tablet devices, alerts are shown as **toast notifications**. On desktop, they appear as inline alerts. This behaviour is controlled by the device detection utility inside `AlertContext`.

---

## Modal System

The modal is rendered globally inside `DefaultLayout`, so it is accessible from any component in the application.

### `useModal` hook

```jsx
import { useModal } from 'thecore-auth';

function DeleteButton({ id, onDeleted }) {
  const { openModal, closeModal } = useModal();

  const handleDelete = () => {
    openModal({
      title: 'Confirm Delete',
      type: 'delete',
      onConfirm: async () => {
        await api.delete(`/api/v2/vehicles/${id}`);
        closeModal();
        onDeleted();
      }
    });
  };

  return <button onClick={handleDelete}>Delete</button>;
}
```

### `openModal` options

| Option | Type | Description |
|---|---|---|
| `component` | `ReactElement` | Content rendered in the modal body |
| `title` | `string` | Modal header text |
| `type` | `'delete' \| 'submit' \| 'custom'` | Controls which footer buttons are shown |
| `modalData` | `object` | State object for form fields inside the modal |
| `formId` | `string` | HTML `id` of the form to submit on Save |
| `onConfirm` | `function` | Called when the confirm/save button is clicked |
| `style` | `object` | Visual customization (see below) |

### Modal types

| Type | Footer buttons |
|---|---|
| `delete` | Cancel, Delete |
| `submit` | Cancel, Reset, Save |
| `custom` | No default buttons (fully custom) |

### Style customization

```jsx
openModal({
  title: 'Edit Vehicle',
  type: 'submit',
  style: {
    width: '600px',
    bgModal: 'bg-white',
    bgOverlay: 'bg-black/50',
    zIndex: 'z-50',
    bgSaveButton: 'bg-blue-600 hover:bg-blue-700 text-white',
    bgCancelButton: 'bg-gray-200 hover:bg-gray-300 text-gray-800',
    bgResetButton: 'bg-yellow-400 hover:bg-yellow-500',
  }
});
```

**Important:** setting any Tailwind class on a button style property **replaces** the entire default value for that property. Use complete class strings.

### Passing state to modal content

Because the modal renders outside the calling component's React tree, you cannot use component-local state directly inside the modal body. Use `modalData` instead:

```jsx
openModal({
  title: 'Edit Vehicle',
  type: 'submit',
  formId: 'vehicle-form',
  modalData: { name: vehicle.name, plate: vehicle.plate },
  component: <VehicleForm />,
  onConfirm: (data) => saveVehicle(data),
});
```

Inside `VehicleForm`, read and write via `useModal`:

```jsx
import { useModal } from 'thecore-auth';

function VehicleForm() {
  const { modalData, handleChange } = useModal();

  return (
    <form id="vehicle-form">
      <input
        name="name"
        value={modalData.name}
        onChange={handleChange}
      />
      <input
        name="plate"
        value={modalData.plate}
        onChange={handleChange}
      />
    </form>
  );
}
```

---

## Loading State

```jsx
import { useLoading } from 'thecore-auth';

function MyComponent() {
  const { setLoading } = useLoading();

  const fetchData = async () => {
    setLoading(true);
    try {
      const { data } = await api.get('/api/v2/vehicles');
      // ...
    } finally {
      setLoading(false);
    }
  };
}
```

The `LoadingProvider` renders a full-screen overlay spinner while `loading` is `true`.

---

## Configuration Hook

Use `useConfig` anywhere in the component tree to access the parsed `config.json` and built-in utilities:

```jsx
import { useConfig } from 'thecore-auth';

function MyComponent() {
  const {
    config,             // parsed config.json object
    formatDate,         // (date) => "dd/mm/yyyy hh:mm:ss"
    openIndexedDB,      // IndexedDB helpers
    getDataIndexedDB,
    setDataIndexedDB,
    generateUniqueId,
  } = useConfig();

  return <p>Connected to: {config.baseUri}</p>;
}
```

---

## Storage Hooks

### `useStorage`

Low-level hook for `localStorage` with automatic JSON serialization:

```jsx
import { useStorage } from 'thecore-auth';

const [value, setValue] = useStorage('my-key', defaultValue);
```

### `useAuthStorage`

Specialised hook that manages the JWT token and user object:

```jsx
import { useAuthStorage } from 'thecore-auth';

const { token, user, setToken, setUser, storageLogout } = useAuthStorage();
```

`storageLogout()` clears both token and user in a single call.

---

## IndexedDB

The library includes hooks and context helpers for persisting data in the browser's IndexedDB — useful for offline-capable applications or caching large datasets locally.

```jsx
import { useIndexedDB } from 'thecore-auth';

const { openDB, getData, setData } = useIndexedDB('my-store');
```

Available operations:

| Function | Description |
|---|---|
| `openIndexedDB(storeName)` | Opens or creates an IndexedDB object store |
| `getDataIndexedDB(store, key)` | Retrieves a record by key |
| `setDataIndexedDB(store, key, value)` | Writes a record |
| `generateUniqueId()` | Generates a unique string ID for new records |
| `setDataWithAutoId(store, value)` | Writes a record with an auto-generated ID |

---

## Utility Hooks

These hooks are exported and available for use in your application:

| Hook | Description |
|---|---|
| `useDevice` | Returns device type: `mobile`, `tablet`, or `desktop` |
| `useOrientation` | Returns screen orientation (`portrait` / `landscape`) |
| `useViewport` | Returns `{ width, height }` of the viewport |
| `useVisibility` | Returns whether the document tab is currently visible |
| `useTitle(title)` | Sets the document `<title>` |
| `useToast` | Programmatic toast notifications |
| `useCalendar` | Date/calendar utilities |
| `useForm` | Form state management helpers |

---

## ActionCable — WebSocket Integration

Thecore backends expose an ActionCable endpoint at `ws://<host>/cable`. The `ActivityLogChannel` delivers real-time events to connected clients.

The thecore-auth library does not bundle an ActionCable client, but you can use the official `@rails/actioncable` package alongside it:

```bash
npm install @rails/actioncable
```

### Connecting

```jsx
import { createConsumer } from '@rails/actioncable';
import { useAuthStorage } from 'thecore-auth';
import { useConfig } from 'thecore-auth';
import { useEffect, useRef } from 'react';

function useActivityLogChannel(onMessage) {
  const { token } = useAuthStorage();
  const { config } = useConfig();
  const cableRef = useRef(null);

  useEffect(() => {
    if (!token || !config) return;

    const wsUrl = config.baseUri.replace(/^http/, 'ws') + '/cable?token=' + token;
    cableRef.current = createConsumer(wsUrl);

    const subscription = cableRef.current.subscriptions.create(
      { channel: 'ActivityLogChannel' },
      {
        connected() {
          console.log('ActivityLog connected');
        },
        received(data) {
          onMessage(data);
        },
      }
    );

    return () => {
      subscription.unsubscribe();
      cableRef.current?.disconnect();
    };
  }, [token, config]);
}
```

See [ACTIONCABLE.md](ACTIONCABLE.md) for the full list of message topics (`general`, `record`, `tcp_debug`) and payload structures.

---

## Styling — CSS Variables

Import the base stylesheet once in your `main.jsx` or global CSS:

```css
@import url('../node_modules/thecore-auth/dist/thecore-auth.css');
```

Override CSS variables in your `:root` selector to match your brand:

```css
:root {
  /* Primary button colour */
  --primary-color: #2563eb;
  --primary-hover-color: #1d4ed8;

  /* Login card */
  --form-card-height: 60vh;
  --form-card-border-radius: 1rem;
  --form-background: #f8fafc;

  /* Inputs */
  --input-background: #ffffff;
  --input-border-color: #cbd5e1;
  --input-label-color: #64748b;

  /* Alerts */
  --alert-danger-bg: #fef2f2;
  --alert-danger-color: #991b1b;
  --alert-success-bg: #f0fdf4;
  --alert-success-color: #166534;
  --alert-warning-bg: #fffbeb;
  --alert-warning-color: #92400e;
  --alert-info-bg: #eff6ff;
  --alert-info-color: #1e40af;

  /* Loading spinner */
  --loader-color: #2563eb;
}
```

Tailwind CSS 4 is used internally by the library. You can use Tailwind in your own components without conflict.

---

## Login Page Customization

Use `useLoginForm` to programmatically override text and styles on the login page:

```jsx
import { useLoginForm } from 'thecore-auth';

function LoginCustomizer() {
  const { setOverrides } = useLoginForm();

  useEffect(() => {
    setOverrides({
      titleText: 'Sign in to MyApp',
      buttonText: 'Sign In',
      containerStyle: 'min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100',
      cardFormStyle: 'shadow-2xl rounded-2xl p-10',
    });
  }, []);

  return null;
}
```

---

## Environment-specific configuration

For multi-environment deployments, you can ship different `config.json` files per environment using your build tool:

```bash
# Vite example
cp public/config.production.json public/config.json
npm run build
```

Or use Vite's `define` plugin to inject `VITE_BASE_URI` and fetch it in `config.json` dynamically. Since `config.json` is fetched at **runtime** (not bundled), it can also be replaced post-build, making it ideal for Docker-based deployments where the backend URL is only known at container start time.

---

## Security Considerations

- JWT tokens are stored in `localStorage`. This is acceptable for internal applications but consider `httpOnly` cookie storage for higher-security use cases.
- The `Authorization: Bearer` header is automatically stripped on 401 responses and the user is forced back to login.
- The `AuthAdmin` middleware checks `user.admin` from the stored user object. The source of truth is always the Thecore backend; the frontend check is a UX convenience, not a security boundary.
- Always use HTTPS in production so that JWT tokens are not transmitted over plain HTTP.

---

## Related Documentation

| Document | Topic |
|---|---|
| [REST_API.md](REST_API.md) | Thecore REST API: endpoints, JWT auth, Ransack, pagination |
| [AUTHENTICATION.md](AUTHENTICATION.md) | Backend auth configuration: Devise, LDAP, Google, Entra ID |
| [ACTIONCABLE.md](ACTIONCABLE.md) | Real-time events via ActionCable |
| [REACT_FRONTEND_WALKTHROUGH.md](REACT_FRONTEND_WALKTHROUGH.md) | Step-by-step tutorial: build a complete React frontend |
