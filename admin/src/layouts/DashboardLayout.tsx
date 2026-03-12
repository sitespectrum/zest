import { useState, useEffect } from "react";
import { Outlet, NavLink, useNavigate, useLocation } from "react-router-dom";
import { Users, Dumbbell, Utensils, Activity, Menu, X, LogOut, Radio, LayoutDashboard, Bell, Trophy } from "lucide-react";

const DashboardLayout = () => {
  const [isSidebarOpen, setSidebarOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const token = localStorage.getItem("admin_token");
    if (!token) {
      navigate("/login");
    }
  }, [navigate]);

  const handleLogout = () => {
    localStorage.removeItem("admin_token");
    localStorage.removeItem("admin_name");
    navigate("/login");
  };

  const getPageTitle = () => {
    if (location.pathname.includes("users")) return "Felhasználók Kezelése";
    if (location.pathname.includes("workouts")) return "Edzések Kezelése";
    if (location.pathname.includes("meals")) return "Étkezések Kezelése";
    if (location.pathname.includes("exercises")) return "Gyakorlatok Kezelése";
    if (location.pathname.includes("sessions")) return "Közös Edzések (Live)";
    if (location.pathname.includes("notifications")) return "Globális Értesítések";
    if (location.pathname.includes("templates")) return "Globális Sablonok";
    return "Zest Admin Panel";
  };

  const navItems = [
    { path: "/dashboard", label: "Áttekintés", icon: LayoutDashboard },
    { path: "/notifications", label: "Értesítések", icon: Bell },
    { path: "/users", label: "Felhasználók", icon: Users },
    { path: "/templates", label: "Globális Sablonok", icon: Trophy },
    { path: "/workouts", label: "Edzések", icon: Dumbbell },
    { path: "/meals", label: "Étkezések", icon: Utensils },
    { path: "/exercises", label: "Gyakorlatok", icon: Activity },
    { path: "/sessions", label: "Élő Sessionök", icon: Radio },
  ];

  return (
    <div className="flex h-screen bg-[#0a0a0a] text-white font-sans overflow-hidden">
      {isSidebarOpen && (
        <div className="fixed inset-0 bg-black/60 z-20 md:hidden backdrop-blur-sm" onClick={() => setSidebarOpen(false)} />
      )}

      <aside className={`fixed md:relative z-30 inset-y-0 left-0 w-72 bg-[#121212] border-r border-[#27272a] transform transition-transform duration-300 ease-in-out flex flex-col ${isSidebarOpen ? "translate-x-0" : "-translate-x-full md:translate-x-0"}`}>
        <div className="flex items-center justify-between px-6 h-20 border-b border-[#27272a] shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#27272a] flex items-center justify-center overflow-hidden p-1.5">
              <img src="/Zest_logo.png" alt="Zest" className="w-full h-full object-contain" />
            </div>
            <span className="text-2xl font-extrabold tracking-wide text-white">Zest<span className="text-[#40ff32]">.</span></span>
          </div>
          <button className="md:hidden text-gray-400 hover:text-white" onClick={() => setSidebarOpen(false)}>
            <X size={24} />
          </button>
        </div>

        <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
          <p className="px-4 text-xs font-bold text-gray-500 uppercase tracking-wider mb-4 mt-2">Adatbázis Kezelés</p>
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              onClick={() => setSidebarOpen(false)}
              className={({ isActive }) => `w-full flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${isActive ? "bg-[#40ff32]/10 text-[#40ff32] shadow-[inset_4px_0_0_0_#40ff32]" : "text-gray-400 hover:bg-[#27272a] hover:text-white"}`}
            >
              <item.icon size={20} />
              <span className="font-semibold text-sm">{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </aside>

      <main className="flex-1 flex flex-col min-w-0 bg-[#0a0a0a]">
        <header className="h-20 px-4 sm:px-8 flex items-center justify-between border-b border-[#27272a] bg-[#121212]/80 backdrop-blur-md sticky top-0 z-10 shrink-0">
          <div className="flex items-center gap-4">
            <button className="p-2 -ml-2 md:hidden text-gray-400 hover:text-white rounded-lg hover:bg-[#27272a] transition" onClick={() => setSidebarOpen(true)}>
              <Menu size={24} />
            </button>
            <h1 className="text-xl sm:text-2xl font-bold text-white tracking-tight">{getPageTitle()}</h1>
          </div>

          <div className="flex items-center gap-4">
            <button onClick={handleLogout} className="p-2 text-red-500 hover:bg-red-500/10 rounded-lg transition" title="Kijelentkezés">
              <LogOut size={20} />
            </button>
          </div>
        </header>

        <div className="flex-1 overflow-auto p-4 sm:p-8">
          <div className="max-w-6xl mx-auto h-full">
            <Outlet /> 
          </div>
        </div>
      </main>
    </div>
  );
};

export default DashboardLayout;