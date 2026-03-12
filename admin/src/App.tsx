import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/Login";
import DashboardLayout from "./layouts/DashboardLayout";
import UsersPage from "./pages/UsersPage";
import PlaceholderPage from "./pages/PlaceholderPage";
import { Dumbbell, Utensils, Activity } from "lucide-react";

const App = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />

        <Route path="/" element={<DashboardLayout />}>
          <Route index element={<Navigate to="/users" replace />} />
          
          <Route path="users" element={<UsersPage />} />
          
          <Route path="workouts" element={<PlaceholderPage icon={Dumbbell} name="Edzések" />} />
          <Route path="meals" element={<PlaceholderPage icon={Utensils} name="Étkezések" />} />
          <Route path="exercises" element={<PlaceholderPage icon={Activity} name="Gyakorlatok" />} />
        </Route>

        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  );
};

export default App;