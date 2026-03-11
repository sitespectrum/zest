import { useEffect, useState } from "react";
import { getUsers, deleteUser, type User } from "./api/api";

const App = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const data = await getUsers();
      setUsers(data);
    } catch (error) {
      console.error(error);
      alert("Nem sikerült kapcsolódni a szerverhez.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleDelete = async (id: number, userName: string) => {
    if (!window.confirm(`Biztosan törölni szeretnéd a következőt: ${userName}? Minden adata (edzések, étkezések, stb.) végleg elvész!`)) {
      return;
    }

    try {
      await deleteUser(id);
      // Ha sikeres a szerveren a törlés, kivesszük a lokális listából is
      setUsers(users.filter((u) => u.id !== id));
      alert("Felhasználó sikeresen törölve!");
    } catch (error) {
      console.error(error);
      alert("Hiba történt a törlés során.");
    }
  };

  return (
    <div className="min-h-screen bg-[#121212] text-white p-4 sm:p-8 font-sans">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col sm:flex-row justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-[#40ff32] flex items-center gap-3">
            Zest Admin Panel
          </h1>
          <button
            onClick={fetchUsers}
            className="mt-4 sm:mt-0 px-5 py-2 bg-[#272727] hover:bg-[#333333] border border-gray-600 rounded-lg transition font-semibold"
          >
            Frissítés
          </button>
        </div>

        <div className="bg-[#1e1e1e] border border-[#2c2c2e] rounded-2xl shadow-xl overflow-hidden">
          <div className="p-6 border-b border-[#2c2c2e] bg-[#272727]">
            <h2 className="text-xl font-semibold">Regisztrált Felhasználók ({users.length})</h2>
          </div>

          <div className="overflow-x-auto">
            {loading ? (
              <div className="p-12 text-center text-[#40ff32] animate-pulse font-semibold">
                Adatok betöltése a szerverről...
              </div>
            ) : (
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-[#2a2a2a] text-gray-400 text-sm uppercase tracking-wider">
                    <th className="p-4 border-b border-[#333]">ID</th>
                    <th className="p-4 border-b border-[#333]">Név</th>
                    <th className="p-4 border-b border-[#333]">Email</th>
                    <th className="p-4 border-b border-[#333]">Adatok</th>
                    <th className="p-4 border-b border-[#333] text-right">Műveletek</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user) => (
                    <tr key={user.id} className="hover:bg-[#272727] transition border-b border-[#2c2c2e]">
                      <td className="p-4 text-gray-500 font-mono">#{user.id}</td>
                      <td className="p-4 font-bold text-white">{user.userName}</td>
                      <td className="p-4 text-gray-400">{user.email}</td>
                      <td className="p-4 text-gray-400 text-sm">
                        {user.gender === "Nő" ? "Nő" : "Férfi"} • {user.height} cm • {user.weight} kg
                      </td>
                      <td className="p-4 text-right">
                        <button
                          onClick={() => handleDelete(user.id, user.userName)}
                          className="px-4 py-2 bg-red-500/10 text-red-500 border border-red-500/20 hover:bg-red-500 hover:text-white rounded-lg transition font-medium"
                        >
                          Törlés
                        </button>
                      </td>
                    </tr>
                  ))}
                  {users.length === 0 && !loading && (
                    <tr>
                      <td colSpan={5} className="p-12 text-center text-gray-500">
                        Nincs regisztrált felhasználó az adatbázisban.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default App;