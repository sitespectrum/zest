import { useEffect, useState } from "react";
import { Users, Dumbbell, Utensils, Activity, Radio, RefreshCw } from "lucide-react";
import { getAdminStats, type AdminStats } from "../api/api";

const DashboardPage = () => {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchStats = async () => {
    setLoading(true);
    try {
      const data = await getAdminStats();
      setStats(data);
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-[80vh] text-[#40ff32] animate-pulse">
        <div className="flex flex-col items-center gap-4">
          <RefreshCw className="animate-spin" size={40} />
          <h2 className="text-xl font-bold">Statisztikák betöltése...</h2>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      
      {/* Új, letisztult Fejléc */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-[#18181b] border border-[#27272a] rounded-3xl p-6 shadow-xl">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Rendszer Áttekintés</h1>
          <p className="text-gray-400 text-sm mt-1">A Zest alkalmazás legfontosabb adatai és valós idejű statisztikái.</p>
        </div>
        <button 
          onClick={fetchStats}
          className="px-5 py-2.5 bg-[#27272a] hover:bg-[#3f3f46] text-white border border-[#3f3f46] rounded-xl transition flex items-center gap-2 font-medium"
        >
          <RefreshCw size={18} /> Frissítés
        </button>
      </div>

      {/* Statisztika Kártyák Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        
        {/* Userek Kártya */}
        <div className="bg-[#18181b] border border-[#27272a] rounded-3xl p-6 shadow-xl flex items-center gap-6 hover:border-[#3f3f46] transition">
          <div className="w-16 h-16 rounded-2xl bg-blue-500/10 text-blue-400 flex items-center justify-center shrink-0">
            <Users size={32} />
          </div>
          <div>
            <p className="text-gray-500 font-medium mb-1">Összes Felhasználó</p>
            <h3 className="text-3xl font-extrabold text-white">{stats?.totalUsers.toLocaleString('hu-HU')}</h3>
          </div>
        </div>

        {/* Élő Sessionök Kártya */}
        <div className="bg-[#18181b] border border-[#27272a] rounded-3xl p-6 shadow-xl flex items-center gap-6 hover:border-[#3f3f46] transition relative overflow-hidden">
          <div className="w-16 h-16 rounded-2xl bg-[#40ff32]/10 text-[#40ff32] flex items-center justify-center shrink-0">
            <Radio size={32} className={stats?.activeSessions && stats.activeSessions > 0 ? "animate-pulse" : ""} />
          </div>
          <div>
            <p className="text-gray-500 font-medium mb-1">Élő / Várakozó Jamek</p>
            <h3 className="text-3xl font-extrabold text-white">{stats?.activeSessions}</h3>
          </div>
        </div>

        {/* Gyakorlatok Kártya */}
        <div className="bg-[#18181b] border border-[#27272a] rounded-3xl p-6 shadow-xl flex items-center gap-6 hover:border-[#3f3f46] transition">
          <div className="w-16 h-16 rounded-2xl bg-purple-500/10 text-purple-400 flex items-center justify-center shrink-0">
            <Activity size={32} />
          </div>
          <div>
            <p className="text-gray-500 font-medium mb-1">Gyakorlat Könyvtár</p>
            <h3 className="text-3xl font-extrabold text-white">{stats?.totalExercises} db</h3>
          </div>
        </div>

        {/* Mai Edzések Kártya */}
        <div className="bg-[#18181b] border border-[#27272a] rounded-3xl p-6 shadow-xl flex flex-col justify-center relative overflow-hidden">
          <div className="flex justify-between items-start mb-4">
            <div className="w-12 h-12 rounded-xl bg-orange-500/10 text-orange-400 flex items-center justify-center">
              <Dumbbell size={24} />
            </div>
            <span className="px-3 py-1 bg-orange-500/20 text-orange-400 text-xs font-bold rounded-full border border-orange-500/20">
              Mai nap
            </span>
          </div>
          <h3 className="text-4xl font-extrabold text-white mb-1">{stats?.todayWorkouts}</h3>
          <p className="text-gray-500 font-medium">Befejezett Edzések (Ma)</p>
          <p className="text-xs text-gray-600 mt-3 border-t border-[#27272a] pt-3">
            Összesen rögzítve: <span className="text-gray-400">{stats?.totalWorkouts.toLocaleString('hu-HU')}</span>
          </p>
        </div>

        {/* Mai Étkezések Kártya */}
        <div className="bg-[#18181b] border border-[#27272a] rounded-3xl p-6 shadow-xl flex flex-col justify-center relative overflow-hidden">
          <div className="flex justify-between items-start mb-4">
            <div className="w-12 h-12 rounded-xl bg-pink-500/10 text-pink-400 flex items-center justify-center">
              <Utensils size={24} />
            </div>
            <span className="px-3 py-1 bg-pink-500/20 text-pink-400 text-xs font-bold rounded-full border border-pink-500/20">
              Mai nap
            </span>
          </div>
          <h3 className="text-4xl font-extrabold text-white mb-1">{stats?.todayMeals}</h3>
          <p className="text-gray-500 font-medium">Rögzített Étkezések (Ma)</p>
          <p className="text-xs text-gray-600 mt-3 border-t border-[#27272a] pt-3">
            Összesen rögzítve: <span className="text-gray-400">{stats?.totalMeals.toLocaleString('hu-HU')}</span>
          </p>
        </div>

      </div>
    </div>
  );
};

export default DashboardPage;