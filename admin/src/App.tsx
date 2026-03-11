import { useEffect, useState } from "react";
import { Users, Dumbbell, Utensils, Activity, Menu, X, Trash2, RefreshCw } from "lucide-react";
import { getUsers, deleteUser, type User } from "./api/api";

const App = () => {
  const [activeTab, setActiveTab] = useState<string>("users");
  const [isSidebarOpen, setSidebarOpen] = useState<boolean>(false);
  
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const data = await getUsers();
      setUsers(data);
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (activeTab === "users") {
      fetchUsers();
    }
  }, [activeTab]);

  const handleDelete = async (id: number, userName: string) => {
    if (!window.confirm(`Biztosan törölni szeretnéd a következőt: ${userName}? Minden adata végleg elvész!`)) {
      return;
    }
    try {
      await deleteUser(id);
      setUsers(users.filter((u) => u.id !== id));
    } catch (error) {
      console.error(error);
      alert("Hiba történt a törlés során.");
    }
  };

  // --- FELHASZNÁLÓK TÁBLÁZAT RENDERELÉSE ---
  const renderUsersTable = () => (
    <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl overflow-hidden flex flex-col">
      <div className="p-6 border-b border-[#27272a] bg-[#121212]/50 flex justify-between items-center">
        <div>
          <h2 className="text-xl font-bold text-white">Regisztrált Felhasználók</h2>
          <p className="text-sm text-gray-500 mt-1">Összesen {users.length} fiók az adatbázisban.</p>
        </div>
        <button
          onClick={fetchUsers}
          className="p-2 sm:px-4 sm:py-2 bg-[#27272a] hover:bg-[#3f3f46] text-gray-300 hover:text-white border border-[#3f3f46] rounded-xl transition flex items-center gap-2"
        >
          <RefreshCw size={16} />
          <span className="hidden sm:inline font-medium">Frissítés</span>
        </button>
      </div>

      <div className="overflow-x-auto">
        {loading ? (
          <div className="p-12 text-center text-[#40ff32] animate-pulse font-semibold flex items-center justify-center gap-3">
            <RefreshCw className="animate-spin" size={20} />
            Adatok betöltése a szerverről...
          </div>
        ) : (
          <table className="w-full text-left border-collapse min-w-[700px]">
            <thead>
              <tr className="bg-[#18181b] text-gray-400 text-xs uppercase tracking-wider">
                <th className="p-4 pl-6 border-b border-[#27272a] font-semibold">ID</th>
                <th className="p-4 border-b border-[#27272a] font-semibold">Név & Email</th>
                <th className="p-4 border-b border-[#27272a] font-semibold">Adatok</th>
                <th className="p-4 pr-6 border-b border-[#27272a] text-right font-semibold">Műveletek</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.id} className="hover:bg-[#27272a]/50 transition border-b border-[#27272a]/50 group">
                  <td className="p-4 pl-6 text-gray-500 font-mono text-sm">#{user.id}</td>
                  <td className="p-4">
                    <p className="font-bold text-white text-base">{user.userName}</p>
                    <p className="text-gray-500 text-sm">{user.email}</p>
                  </td>
                  <td className="p-4">
                    <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#27272a] text-gray-300 text-xs font-medium border border-[#3f3f46]">
                      <span>{user.gender === "Nő" ? "Nő" : "Férfi"}</span>
                      <span className="w-1 h-1 rounded-full bg-gray-500"></span>
                      <span>{user.height} cm</span>
                      <span className="w-1 h-1 rounded-full bg-gray-500"></span>
                      <span>{user.weight} kg</span>
                    </div>
                  </td>
                  <td className="p-4 pr-6 text-right">
                    <button
                      onClick={() => handleDelete(user.id, user.userName)}
                      className="p-2 sm:px-4 sm:py-2 bg-red-500/10 text-red-500 border border-red-500/20 hover:bg-red-500 hover:text-white rounded-xl transition font-medium flex items-center justify-center gap-2 ml-auto"
                    >
                      <Trash2 size={16} />
                      <span className="hidden sm:inline">Törlés</span>
                    </button>
                  </td>
                </tr>
              ))}
              {users.length === 0 && !loading && (
                <tr>
                  <td colSpan={4} className="p-12 text-center text-gray-500">
                    Nincs regisztrált felhasználó az adatbázisban.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );

  return (
    <div className="flex h-screen bg-[#0a0a0a] text-white font-sans overflow-hidden">
      
      {/* SÖTÉTÍTŐ RÉTEG MOBILON */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/60 z-20 md:hidden backdrop-blur-sm"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* --- SIDEBAR --- */}
      <aside 
        className={`fixed md:relative z-30 inset-y-0 left-0 w-72 bg-[#121212] border-r border-[#27272a] transform transition-transform duration-300 ease-in-out flex flex-col ${
          isSidebarOpen ? "translate-x-0" : "-translate-x-full md:translate-x-0"
        }`}
      >
        {/* Logó és Cím */}
        <div className="flex items-center justify-between px-6 h-20 border-b border-[#27272a] shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#27272a] border border-[#3f3f46] flex items-center justify-center overflow-hidden p-1.5">
              {/* Ha beillesztetted a logót a public mappába, ez meg fog jelenni. Ha nincs kép, egy zöld Z betű lesz helyette. */}
              <img 
                src="/Zest_logo.png" 
                alt="Zest" 
                className="w-full h-full object-contain"
                onError={(e) => {
                  e.currentTarget.style.display = 'none';
                  e.currentTarget.parentElement!.innerHTML = '<span class="text-[#40ff32] font-bold text-xl">Z</span>';
                }} 
              />
            </div>
            <span className="text-2xl font-extrabold tracking-wide text-white">
              Zest<span className="text-[#40ff32]">.</span>
            </span>
          </div>
          
          <button className="md:hidden text-gray-400 hover:text-white" onClick={() => setSidebarOpen(false)}>
            <X size={24} />
          </button>
        </div>

        {/* Menüpontok */}
        <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
          <p className="px-4 text-xs font-bold text-gray-500 uppercase tracking-wider mb-4 mt-2">
            Adatbázis Kezelés
          </p>

          <button 
            onClick={() => { setActiveTab("users"); setSidebarOpen(false); }} 
            className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              activeTab === "users" ? "bg-[#40ff32]/10 text-[#40ff32] shadow-[inset_4px_0_0_0_#40ff32]" : "text-gray-400 hover:bg-[#27272a] hover:text-white"
            }`}
          >
            <Users size={20} className={activeTab === "users" ? "text-[#40ff32]" : "text-gray-400"} />
            <span className="font-semibold text-sm">Felhasználók</span>
          </button>

          <button 
            onClick={() => { setActiveTab("workouts"); setSidebarOpen(false); }} 
            className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              activeTab === "workouts" ? "bg-[#40ff32]/10 text-[#40ff32] shadow-[inset_4px_0_0_0_#40ff32]" : "text-gray-400 hover:bg-[#27272a] hover:text-white"
            }`}
          >
            <Dumbbell size={20} className={activeTab === "workouts" ? "text-[#40ff32]" : "text-gray-400"} />
            <span className="font-semibold text-sm">Edzések</span>
          </button>

          <button 
            onClick={() => { setActiveTab("meals"); setSidebarOpen(false); }} 
            className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              activeTab === "meals" ? "bg-[#40ff32]/10 text-[#40ff32] shadow-[inset_4px_0_0_0_#40ff32]" : "text-gray-400 hover:bg-[#27272a] hover:text-white"
            }`}
          >
            <Utensils size={20} className={activeTab === "meals" ? "text-[#40ff32]" : "text-gray-400"} />
            <span className="font-semibold text-sm">Étkezések</span>
          </button>

          <button 
            onClick={() => { setActiveTab("exercises"); setSidebarOpen(false); }} 
            className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              activeTab === "exercises" ? "bg-[#40ff32]/10 text-[#40ff32] shadow-[inset_4px_0_0_0_#40ff32]" : "text-gray-400 hover:bg-[#27272a] hover:text-white"
            }`}
          >
            <Activity size={20} className={activeTab === "exercises" ? "text-[#40ff32]" : "text-gray-400"} />
            <span className="font-semibold text-sm">Gyakorlatok</span>
          </button>
        </nav>
      </aside>

      {/* --- MAIN CONTENT --- */}
      <main className="flex-1 flex flex-col min-w-0 bg-[#0a0a0a]">
        
        {/* Fejléc */}
        <header className="h-20 px-4 sm:px-8 flex items-center justify-between border-b border-[#27272a] bg-[#121212]/80 backdrop-blur-md sticky top-0 z-10 shrink-0">
          <div className="flex items-center gap-4">
            <button 
              className="p-2 -ml-2 md:hidden text-gray-400 hover:text-white rounded-lg hover:bg-[#27272a] transition" 
              onClick={() => setSidebarOpen(true)}
            >
              <Menu size={24} />
            </button>
            <h1 className="text-xl sm:text-2xl font-bold text-white tracking-tight">
              {activeTab === "users" && "Felhasználók Kezelése"}
              {activeTab === "workouts" && "Edzések Kezelése"}
              {activeTab === "meals" && "Étkezések Kezelése"}
              {activeTab === "exercises" && "Gyakorlatok Kezelése"}
            </h1>
          </div>

          {/* Admin Avatar */}
          <div className="flex items-center gap-3">
             <div className="w-10 h-10 rounded-full bg-[#18181b] flex items-center justify-center border-2 border-[#40ff32]/30 text-[#40ff32] font-bold shadow-[0_0_10px_rgba(64,255,50,0.1)]">
               A
             </div>
          </div>
        </header>

        {/* Dinamikus Tartalom */}
        <div className="flex-1 overflow-auto p-4 sm:p-8 custom-scrollbar">
          <div className="max-w-6xl mx-auto h-full">
            {activeTab === "users" && renderUsersTable()}
            
            {activeTab !== "users" && (
              <div className="flex flex-col items-center justify-center h-[60vh] border-2 border-dashed border-[#27272a] rounded-3xl bg-[#121212]/30">
                <div className="w-20 h-20 bg-[#27272a] rounded-2xl flex items-center justify-center mb-4 text-[#40ff32]">
                   {activeTab === 'workouts' && <Dumbbell size={40} />}
                   {activeTab === 'meals' && <Utensils size={40} />}
                   {activeTab === 'exercises' && <Activity size={40} />}
                </div>
                <h3 className="text-xl font-bold text-white mb-2">Hamarosan érkezik!</h3>
                <p className="text-gray-500 text-center max-w-sm">
                  Az adatbázis ezen részének ({activeTab}) kezelőfelülete még fejlesztés alatt áll.
                </p>
              </div>
            )}
          </div>
        </div>

      </main>
    </div>
  );
};

export default App;