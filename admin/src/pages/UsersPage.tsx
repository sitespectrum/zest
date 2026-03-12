import { useEffect, useState } from "react";
import { Trash2, RefreshCw } from "lucide-react";
import { getUsers, deleteUser, type User } from "../api/api";

const UsersPage = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const data = await getUsers();
      setUsers(data);
    } catch (error: any) {
      if (error.message === "unauthorized") {
        alert("A munkamenet lejárt! Kérlek jelentkezz be újra.");
        localStorage.clear();
        window.location.href = "/login";
      }
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleDelete = async (id: number, userName: string) => {
    if (!window.confirm(`Biztosan törölni szeretnéd a következőt: ${userName}? Minden adata végleg elvész!`)) return;
    try {
      await deleteUser(id);
      setUsers(users.filter((u) => u.id !== id));
    } catch (error: any) {
      if (error.message === "unauthorized") {
        alert("A munkamenet lejárt! Kérlek jelentkezz be újra.");
        localStorage.clear();
        window.location.href = "/login";
      } else {
        alert("Hiba történt a törlés során.");
      }
      console.error(error);
    }
  };

  return (
    <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl overflow-hidden flex flex-col">
      <div className="p-6 border-b border-[#27272a] bg-[#121212]/50 flex justify-between items-center">
        <div>
          <h2 className="text-xl font-bold text-white">Regisztrált Felhasználók</h2>
          <p className="text-sm text-gray-500 mt-1">Összesen {users.length} fiók az adatbázisban.</p>
        </div>
        <button onClick={fetchUsers} className="p-2 sm:px-4 sm:py-2 bg-[#27272a] hover:bg-[#3f3f46] text-gray-300 hover:text-white border border-[#3f3f46] rounded-xl transition flex items-center gap-2">
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
                    <button onClick={() => handleDelete(user.id, user.userName)} className="p-2 sm:px-4 sm:py-2 bg-red-500/10 text-red-500 border border-red-500/20 hover:bg-red-500 hover:text-white rounded-xl transition font-medium flex items-center justify-center gap-2 ml-auto">
                      <Trash2 size={16} />
                      <span className="hidden sm:inline">Törlés</span>
                    </button>
                  </td>
                </tr>
              ))}
              {users.length === 0 && !loading && (
                <tr>
                  <td colSpan={4} className="p-12 text-center text-gray-500">Nincs regisztrált felhasználó az adatbázisban.</td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default UsersPage;