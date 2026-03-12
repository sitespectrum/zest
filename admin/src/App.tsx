import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/Login";
import DashboardLayout from "./layouts/DashboardLayout";
import UsersPage from "./pages/UsersPage";
import ExercisesPage from "./pages/ExercisesPage";
import WorkoutsPage from "./pages/WorkoutsPage";
import MealsPage from "./pages/MealsPage";
import SessionsPage from "./pages/SessionsPage";
import DashboardPage from "./pages/DashboardPage";
import NotificationsPage from "./pages/NotificationsPage";
import TemplatesPage from "./pages/TemplatesPage";

const App = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />

        <Route path="/" element={<DashboardLayout />}>
        <Route index element={<Navigate to="/dashboard" replace />} />
          
          <Route path="users" element={<UsersPage />} />
          <Route path="exercises" element={<ExercisesPage />} />
          <Route path="workouts" element={<WorkoutsPage />} />
          <Route path="meals" element={<MealsPage />} />
          <Route path="sessions" element={<SessionsPage />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="notifications" element={<NotificationsPage />} />
          <Route path="templates" element={<TemplatesPage />} />
        </Route>

        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  );
};

export default App;