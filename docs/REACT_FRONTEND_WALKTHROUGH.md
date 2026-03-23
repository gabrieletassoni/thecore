# React Frontend Walkthrough — Fleet Management App

This walkthrough builds a complete React frontend for a **Fleet Management** application backed by a Thecore backend. By the end you will have:

- A login page connected to Thecore JWT authentication
- A private dashboard listing vehicles from the Thecore REST API
- A CRUD modal for creating and editing vehicles
- An admin-only management page
- Real-time updates via ActionCable
- A styled interface using the thecore-auth CSS variable system

The walkthrough assumes the Thecore backend from [WALKTHROUGH.md](WALKTHROUGH.md) is already running locally at `http://localhost:3000`.

---

## Prerequisites

- Node.js 18+ installed
- Thecore backend running (see [WALKTHROUGH.md](WALKTHROUGH.md))
- Familiarity with React and JSX

---

## Step 1 — Create the React project

```bash
npm create vite@latest fleet-frontend -- --template react
cd fleet-frontend
npm install
```

Install thecore-auth and its required peer package for ActionCable:

```bash
npm install thecore-auth @rails/actioncable
```

Your `package.json` dependencies will now include:

```json
{
  "dependencies": {
    "thecore-auth": "*",
    "@rails/actioncable": "*",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
```

---

## Step 2 — Create `public/config.json`

This file is the single source of configuration for thecore-auth. It is fetched at runtime, so it can be swapped without rebuilding.

```json
{
  "baseUri": "http://localhost:3000",
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
    "name": "Fleet Manager",
    "version": "1.0.0",
    "debug": false
  },
  "autoLogin": false,
  "messages": {
    "unauthorized": "You are not authorised to access this page.",
    "notFound": "Resource not found.",
    "genericError": "Unexpected error (status: {{status}})"
  }
}
```

---

## Step 3 — Bootstrap providers in `src/main.jsx`

Replace the contents of `src/main.jsx`:

```jsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import {
  BrowserRouter,
  LoadingProvider,
  ConfigProvider,
  AlertProvider,
  AuthProvider,
  LoginFormProvider,
  ModalProvider,
} from 'thecore-auth';
import App from './App';
import 'thecore-auth/dist/thecore-auth.css';
import './index.css';

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

---

## Step 4 — Wire up routing in `src/App.jsx`

```jsx
import { RouteProvider, PackageRoutes } from 'thecore-auth';
import fleetLogo from './assets/fleet-logo.svg';
import Header from './components/Header';

export default function App() {
  return (
    <RouteProvider>
      <PackageRoutes
        logo={<img src={fleetLogo} alt="Fleet Manager" className="w-32" />}
        headerComponent={<Header />}
        showHeaderOnLogin={false}
      />
    </RouteProvider>
  );
}
```

At this point, running `npm run dev` will serve a login page at `http://localhost:5173`. Enter Thecore admin credentials — the user is redirected to `/dashboard/` after a successful login.

---

## Step 5 — Create a simple Header component

```jsx
// src/components/Header.jsx
import { useAuth, useConfig } from 'thecore-auth';

export default function Header() {
  const { logout } = useAuth();
  const { config } = useConfig();

  return (
    <header className="flex items-center justify-between px-6 py-3 bg-blue-700 text-white shadow">
      <span className="font-bold text-lg">{config?.app?.name}</span>
      <button
        onClick={logout}
        className="text-sm bg-white text-blue-700 px-3 py-1 rounded hover:bg-blue-50"
      >
        Logout
      </button>
    </header>
  );
}
```

---

## Step 6 — Create an API helper

Centralise the Axios instance so all pages share the same configured client.

```jsx
// src/api/useApi.jsx
import { fetchAxiosConfig, useAlert } from 'thecore-auth';
import { useNavigate } from 'thecore-auth';

export function useApi() {
  const { activeAlert } = useAlert();
  const navigate = useNavigate();

  return fetchAxiosConfig(
    (msg) => activeAlert('danger', msg),
    () => navigate('/not-found'),
    (msg) => activeAlert('warning', msg)
  );
}
```

---

## Step 7 — Build the Vehicle List dashboard

```jsx
// src/pages/Dashboard.jsx
import { useEffect, useState } from 'react';
import { useLoading, useAlert, useModal } from 'thecore-auth';
import { useApi } from '../api/useApi';
import VehicleForm from '../components/VehicleForm';

export default function Dashboard() {
  const api = useApi();
  const { setLoading } = useLoading();
  const { activeAlert } = useAlert();
  const { openModal, closeModal } = useModal();

  const [vehicles, setVehicles] = useState([]);

  const loadVehicles = async () => {
    setLoading(true);
    try {
      const { data } = await api.get('/api/v2/vehicles');
      setVehicles(data);
    } catch {
      // errors are handled by the Axios interceptor
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadVehicles();
  }, []);

  const handleCreate = () => {
    openModal({
      title: 'New Vehicle',
      type: 'submit',
      formId: 'vehicle-form',
      modalData: { name: '', plate: '', vehicle_type: '' },
      component: <VehicleForm />,
      onConfirm: async (formData) => {
        try {
          await api.post('/api/v2/vehicles', { vehicle: formData });
          activeAlert('success', 'Vehicle created.');
          closeModal();
          loadVehicles();
        } catch {
          // handled by interceptor
        }
      },
    });
  };

  const handleEdit = (vehicle) => {
    openModal({
      title: `Edit — ${vehicle.name}`,
      type: 'submit',
      formId: 'vehicle-form',
      modalData: { name: vehicle.name, plate: vehicle.plate, vehicle_type: vehicle.vehicle_type },
      component: <VehicleForm />,
      onConfirm: async (formData) => {
        try {
          await api.put(`/api/v2/vehicles/${vehicle.id}`, { vehicle: formData });
          activeAlert('success', 'Vehicle updated.');
          closeModal();
          loadVehicles();
        } catch {
          // handled by interceptor
        }
      },
    });
  };

  const handleDelete = (vehicle) => {
    openModal({
      title: `Delete ${vehicle.name}?`,
      type: 'delete',
      onConfirm: async () => {
        try {
          await api.delete(`/api/v2/vehicles/${vehicle.id}`);
          activeAlert('success', 'Vehicle deleted.');
          closeModal();
          loadVehicles();
        } catch {
          // handled by interceptor
        }
      },
    });
  };

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-4">
        <h1 className="text-2xl font-bold">Vehicles</h1>
        <button
          onClick={handleCreate}
          className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
        >
          + New vehicle
        </button>
      </div>

      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="bg-gray-100 text-left">
            <th className="p-2 border">Name</th>
            <th className="p-2 border">Plate</th>
            <th className="p-2 border">Type</th>
            <th className="p-2 border">Actions</th>
          </tr>
        </thead>
        <tbody>
          {vehicles.map((v) => (
            <tr key={v.id} className="hover:bg-gray-50">
              <td className="p-2 border">{v.name}</td>
              <td className="p-2 border">{v.plate}</td>
              <td className="p-2 border">{v.vehicle_type}</td>
              <td className="p-2 border space-x-2">
                <button
                  onClick={() => handleEdit(v)}
                  className="text-blue-600 hover:underline"
                >
                  Edit
                </button>
                <button
                  onClick={() => handleDelete(v)}
                  className="text-red-600 hover:underline"
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {vehicles.length === 0 && (
        <p className="mt-4 text-gray-500 text-sm">No vehicles found.</p>
      )}
    </div>
  );
}
```

---

## Step 8 — Create the Vehicle Form modal component

The modal body reads and writes via `useModal` instead of local state, because it renders outside the calling component's tree.

```jsx
// src/components/VehicleForm.jsx
import { useModal } from 'thecore-auth';

export default function VehicleForm() {
  const { modalData, handleChange } = useModal();

  return (
    <form id="vehicle-form" className="flex flex-col gap-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
        <input
          name="name"
          value={modalData?.name || ''}
          onChange={handleChange}
          className="w-full border rounded px-3 py-2 text-sm"
          required
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Plate</label>
        <input
          name="plate"
          value={modalData?.plate || ''}
          onChange={handleChange}
          className="w-full border rounded px-3 py-2 text-sm"
          required
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
        <select
          name="vehicle_type"
          value={modalData?.vehicle_type || ''}
          onChange={handleChange}
          className="w-full border rounded px-3 py-2 text-sm"
        >
          <option value="">— Select —</option>
          <option value="truck">Truck</option>
          <option value="van">Van</option>
          <option value="car">Car</option>
        </select>
      </div>
    </form>
  );
}
```

---

## Step 9 — Register routes

Route registration in thecore-auth works by calling `useRoutesInjection` inside a component that is rendered within `RouteProvider`. Create a route registry component:

```jsx
// src/routes/AppRoutes.jsx
import { useEffect } from 'react';
import { useRoutesInjection, Route } from 'thecore-auth';
import Dashboard from '../pages/Dashboard';
import AdminPanel from '../pages/AdminPanel';
import { AuthAdmin } from 'thecore-auth';

export default function AppRoutes() {
  const { addPrivateRoute } = useRoutesInjection();

  useEffect(() => {
    addPrivateRoute(<Route path="/dashboard/:userId" element={<Dashboard />} />);
    addPrivateRoute(
      <Route element={<AuthAdmin />}>
        <Route path="/admin" element={<AdminPanel />} />
      </Route>
    );
  }, []);

  return null;
}
```

Mount `AppRoutes` inside `App.jsx` before `PackageRoutes`:

```jsx
// src/App.jsx
import { RouteProvider, PackageRoutes } from 'thecore-auth';
import Header from './components/Header';
import AppRoutes from './routes/AppRoutes';
import fleetLogo from './assets/fleet-logo.svg';

export default function App() {
  return (
    <RouteProvider>
      <AppRoutes />
      <PackageRoutes
        logo={<img src={fleetLogo} alt="Fleet Manager" />}
        headerComponent={<Header />}
        showHeaderOnLogin={false}
      />
    </RouteProvider>
  );
}
```

---

## Step 10 — Create the Admin-only panel

```jsx
// src/pages/AdminPanel.jsx
import { useEffect, useState } from 'react';
import { useLoading } from 'thecore-auth';
import { useApi } from '../api/useApi';

export default function AdminPanel() {
  const api = useApi();
  const { setLoading } = useLoading();
  const [users, setUsers] = useState([]);

  useEffect(() => {
    setLoading(true);
    api.get('/api/v2/users')
      .then(({ data }) => setUsers(data))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">User Administration</h1>
      <ul className="divide-y">
        {users.map((u) => (
          <li key={u.id} className="py-2 flex items-center justify-between">
            <span>{u.email}</span>
            {u.admin && (
              <span className="text-xs bg-red-100 text-red-700 px-2 py-0.5 rounded">Admin</span>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

Non-admin users who navigate to `/admin` will be automatically redirected with an alert — the `AuthAdmin` middleware handles this.

---

## Step 11 — Add real-time updates via ActionCable

Extend the `Dashboard` to receive live vehicle updates from the Thecore backend's `ActivityLogChannel`.

```jsx
// src/hooks/useVehicleChannel.js
import { useEffect, useRef } from 'react';
import { createConsumer } from '@rails/actioncable';
import { useAuthStorage, useConfig } from 'thecore-auth';

export function useVehicleChannel(onUpdate) {
  const { token } = useAuthStorage();
  const { config } = useConfig();
  const cableRef = useRef(null);

  useEffect(() => {
    if (!token || !config?.baseUri) return;

    const wsUrl = config.baseUri.replace(/^http/, 'ws') + '/cable?token=' + token;
    cableRef.current = createConsumer(wsUrl);

    const subscription = cableRef.current.subscriptions.create(
      { channel: 'ActivityLogChannel' },
      {
        received(data) {
          // Thecore sends { topic: 'record', ... } for model changes
          if (data.topic === 'record') {
            onUpdate(data);
          }
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

Use it in `Dashboard.jsx`:

```jsx
import { useVehicleChannel } from '../hooks/useVehicleChannel';

// Inside the Dashboard component, after the useEffect for loadVehicles:
useVehicleChannel((event) => {
  // Reload the list whenever any record changes
  if (event.model === 'Vehicle') {
    loadVehicles();
  }
});
```

See [ACTIONCABLE.md](ACTIONCABLE.md) for the full payload structure and all available topics.

---

## Step 12 — Style the application

Add a `src/styles/theme.css` file and import it in `main.jsx`:

```css
/* src/styles/theme.css */
@import url('../node_modules/thecore-auth/dist/thecore-auth.css');

:root {
  /* Primary brand colour */
  --primary-color: #1d4ed8;
  --primary-hover-color: #1e40af;

  /* Login page */
  --form-card-height: 55vh;
  --form-card-border-radius: 1.25rem;
  --form-background: #f0f9ff;
  --input-background: #ffffff;
  --input-border-color: #bfdbfe;
  --input-label-color: #1e40af;

  /* Loading spinner */
  --loader-color: #1d4ed8;

  /* Alerts */
  --alert-success-bg: #f0fdf4;
  --alert-success-color: #166534;
  --alert-danger-bg: #fef2f2;
  --alert-danger-color: #991b1b;
  --alert-warning-bg: #fffbeb;
  --alert-warning-color: #92400e;
  --alert-info-bg: #eff6ff;
  --alert-info-color: #1e40af;
}
```

In `main.jsx`, replace the existing CSS import with:

```jsx
import './styles/theme.css';
```

---

## Step 13 — Ransakc-based search

Thecore's REST API supports Ransack predicates for server-side filtering. Add a search bar to the dashboard:

```jsx
// Inside Dashboard.jsx — add a search state and update loadVehicles

const [search, setSearch] = useState('');

const loadVehicles = async (query = '') => {
  setLoading(true);
  try {
    const params = query ? { 'q[name_or_plate_cont]': query } : {};
    const { data } = await api.get('/api/v2/vehicles', { params });
    setVehicles(data);
  } finally {
    setLoading(false);
  }
};

// Add this above the table:
<input
  type="search"
  placeholder="Search by name or plate…"
  value={search}
  onChange={(e) => setSearch(e.target.value)}
  onKeyDown={(e) => e.key === 'Enter' && loadVehicles(search)}
  className="border rounded px-3 py-2 text-sm w-64"
/>
```

See [REST_API.md](REST_API.md) for the full list of Ransack predicates (`_cont`, `_eq`, `_gt`, `_lt`, etc.) and pagination parameters (`page`, `per_page`).

---

## Step 14 — Paginate results

```jsx
const [page, setPage] = useState(1);
const [totalPages, setTotalPages] = useState(1);
const PER_PAGE = 20;

const loadVehicles = async (query = '', pageNum = 1) => {
  setLoading(true);
  try {
    const { data, headers } = await api.get('/api/v2/vehicles', {
      params: {
        'q[name_or_plate_cont]': query || undefined,
        page: pageNum,
        per_page: PER_PAGE,
      },
    });
    setVehicles(data);
    // Thecore returns total count in headers
    const total = parseInt(headers['x-total-count'] || '0', 10);
    setTotalPages(Math.ceil(total / PER_PAGE));
    setPage(pageNum);
  } finally {
    setLoading(false);
  }
};

// Pagination controls:
<div className="flex gap-2 mt-4 justify-center">
  <button
    disabled={page <= 1}
    onClick={() => loadVehicles(search, page - 1)}
    className="px-3 py-1 border rounded disabled:opacity-40"
  >
    Previous
  </button>
  <span className="px-3 py-1 text-sm text-gray-600">
    Page {page} of {totalPages}
  </span>
  <button
    disabled={page >= totalPages}
    onClick={() => loadVehicles(search, page + 1)}
    className="px-3 py-1 border rounded disabled:opacity-40"
  >
    Next
  </button>
</div>
```

---

## Step 15 — Production build

```bash
npm run build
```

The output is in `dist/`. Before deploying, update `public/config.json` with the production backend URL:

```json
{
  "baseUri": "https://fleet.example.com",
  ...
}
```

Because `config.json` is not bundled (it is fetched at runtime), you can also copy it into the `dist/` folder after the build or inject it via your Docker entrypoint script — the application reads it fresh on every page load.

### Docker example

```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
# config.json is bind-mounted or written by entrypoint
```

```bash
# At container start, write config.json from environment variables:
cat > /usr/share/nginx/html/config.json <<EOF
{
  "baseUri": "${BACKEND_URL}",
  ...
}
EOF
```

---

## What you have built

| Feature | How it works |
|---|---|
| JWT login | `AuthContext` → POST to Thecore `/api/v2/authenticate` |
| Session management | Configurable timeout or infinite heartbeat mode |
| Protected routes | `AuthPage` middleware wraps all private routes |
| Admin routes | `AuthAdmin` checks `user.admin` field |
| REST CRUD | Axios instance with auto Bearer token injection |
| Server-side search | Ransack predicates via query params |
| Pagination | `page` / `per_page` params + `x-total-count` header |
| Real-time updates | ActionCable `ActivityLogChannel` subscription |
| Modal CRUD | `ModalContext` with `modalData` state sharing |
| Alerts | `AlertContext` with four types, mobile-aware toasts |
| Theming | CSS variables override in `:root` |

---

## Next steps

- Add file upload support (ActiveStorage) — use `FormData` with the Axios instance; see [REST_API.md](REST_API.md) for the `remove_<attribute>` deletion pattern
- Add Google or Microsoft login on the backend — see [AUTHENTICATION.md](AUTHENTICATION.md); the frontend login flow remains identical (the same JWT is returned regardless of backend auth provider)
- Build offline support using the IndexedDB hooks from `useConfig` to cache frequently accessed data

---

## Reference

| Document | Topic |
|---|---|
| [REACT_FRONTEND.md](REACT_FRONTEND.md) | Full API reference for thecore-auth |
| [REST_API.md](REST_API.md) | Thecore REST endpoints, Ransack, pagination, file uploads |
| [ACTIONCABLE.md](ACTIONCABLE.md) | WebSocket channel topics and payloads |
| [AUTHENTICATION.md](AUTHENTICATION.md) | Backend auth: LDAP, Google OAuth2, Entra ID |
| [WALKTHROUGH.md](WALKTHROUGH.md) | Building the Thecore backend |
