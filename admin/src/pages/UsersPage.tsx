import { useEffect, useState } from "react";
import { Trash2, RefreshCw, Edit2, X, ImageOff, Search, Eye, Dumbbell, Utensils, Users } from "lucide-react";
import { getUsers, deleteUser, updateUser, removeUserProfilePicture, getUserDetails, type User, type UserDetails } from "../api/api";

const UsersPage = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState("");

  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);

  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [selectedUserDetails, setSelectedUserDetails] = useState<UserDetails | null>(null);
  const [detailsLoading, setDetailsLoading] = useState(false);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const data = await getUsers();
      setUsers(data);
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
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
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert("Hiba történt a törlés során.");
    }
  };

  const openEditModal = (user: User) => {
    setEditingUser({ ...user });
    setIsEditModalOpen(true);
  };

  const openDetailsModal = async (id: number) => {
    setIsDetailsModalOpen(true);
    setDetailsLoading(true);
    setSelectedUserDetails(null);
    try {
      const details = await getUserDetails(id);
      setSelectedUserDetails(details);
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else {
        alert("Hiba történt az adatok lekérésekor.");
        setIsDetailsModalOpen(false);
      }
    } finally {
      setDetailsLoading(false);
    }
  };

  const handleUpdateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser) return;
    try {
      await updateUser(editingUser.id, editingUser);
      setUsers(users.map(u => (u.id === editingUser.id ? editingUser : u)));
      setIsEditModalOpen(false);
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert("Hiba történt a mentés során.");
    }
  };

  const handleRemoveProfilePicture = async () => {
    if (!editingUser) return;
    if (!window.confirm("Biztosan törlöd a felhasználó profilképét?")) return;
    try {
      await removeUserProfilePicture(editingUser.id);
      setEditingUser({ ...editingUser, profilePicture: undefined });
      setUsers(users.map(u => (u.id === editingUser.id ? { ...u, profilePicture: undefined } : u)));
    } catch (error: any) {
      if (error.message === "unauthorized") window.location.href = "/login";
      else alert("Hiba történt a profilkép törlése során.");
    }
  };

  const getImgSrc = (base64: string) => {
    if (base64.startsWith("data:image")) return base64;
    return `data:image/jpeg;base64,${base64}`;
  };

  const filteredUsers = users.filter(u => 
    u.userName.toLowerCase().includes(searchQuery.toLowerCase()) || 
    u.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
    u.id.toString() === searchQuery
  );

  return (
    <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl overflow-hidden flex flex-col relative h-[85vh]">
      <div className="p-6 border-b border-[#27272a] bg-[#121212]/50 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-white">Regisztrált Felhasználók</h2>
          <p className="text-sm text-gray-500 mt-1">Összesen {users.length} fiók az adatbázisban.</p>
        </div>
        <div className="flex w-full sm:w-auto gap-3">
          <div className="relative flex-1 sm:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input 
              type="text" 
              placeholder="Keresés (ID / Név / Email)..." 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-[#27272a] border border-[#3f3f46] text-white pl-10 pr-4 py-2 rounded-xl focus:border-[#40ff32] outline-none transition"
            />
          </div>
          <button onClick={fetchUsers} className="p-2 sm:px-4 sm:py-2 bg-[#27272a] hover:bg-[#3f3f46] text-gray-300 hover:text-white border border-[#3f3f46] rounded-xl transition flex items-center gap-2">
            <RefreshCw size={16} />
            <span className="hidden sm:inline font-medium">Frissítés</span>
          </button>
        </div>
      </div>

      <div className="overflow-x-auto flex-1 custom-scrollbar">
        {loading ? (
          <div className="p-12 text-center text-[#40ff32] animate-pulse font-semibold flex items-center justify-center gap-3">
            <RefreshCw className="animate-spin" size={20} /> Adatok betöltése a szerverről...
          </div>
        ) : (
          <table className="w-full text-left border-collapse min-w-[900px]">
            <thead className="sticky top-0 z-10 bg-[#18181b] shadow-sm">
              <tr className="bg-[#18181b] text-gray-400 text-xs uppercase tracking-wider">
                <th className="p-4 pl-6 border-b border-[#27272a] font-semibold">Profil</th>
                <th className="p-4 border-b border-[#27272a] font-semibold">ID</th>
                <th className="p-4 border-b border-[#27272a] font-semibold">Név & Email</th>
                <th className="p-4 border-b border-[#27272a] font-semibold">Adatok</th>
                <th className="p-4 pr-6 border-b border-[#27272a] text-right font-semibold">Műveletek</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map((user) => (
                <tr key={user.id} className="hover:bg-[#27272a]/50 transition border-b border-[#27272a]/50 group">
                  <td className="p-4 pl-6">
                    <div className="w-10 h-10 rounded-full bg-[#27272a] border border-[#3f3f46] overflow-hidden flex items-center justify-center">
                      {user.profilePicture ? (
                        <img src={getImgSrc(user.profilePicture)} alt="profile" className="w-full h-full object-cover" />
                      ) : (
                        <span className="text-gray-500 font-bold">{user.userName.charAt(0).toUpperCase()}</span>
                      )}
                    </div>
                  </td>
                  <td className="p-4 text-gray-500 font-mono text-sm">#{user.id}</td>
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
                    <div className="flex justify-end gap-2">
                      <button onClick={() => openDetailsModal(user.id)} title="Mély Elemzés (Deep Dive)" className="p-2 bg-purple-500/10 text-purple-400 border border-purple-500/20 hover:bg-purple-500 hover:text-white rounded-xl transition font-medium flex items-center gap-2">
                        <Eye size={16} /> Részletek
                      </button>
                      <button onClick={() => openEditModal(user)} title="Szerkesztés" className="p-2 bg-blue-500/10 text-blue-400 border border-blue-500/20 hover:bg-blue-500 hover:text-white rounded-xl transition font-medium flex items-center gap-2">
                        <Edit2 size={16} />
                      </button>
                      <button onClick={() => handleDelete(user.id, user.userName)} title="Törlés" className="p-2 bg-red-500/10 text-red-500 border border-red-500/20 hover:bg-red-500 hover:text-white rounded-xl transition font-medium flex items-center gap-2">
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filteredUsers.length === 0 && !loading && (
                <tr>
                  <td colSpan={5} className="p-12 text-center text-gray-500">Nincs a keresésnek megfelelő felhasználó.</td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>

      {isDetailsModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl w-full max-w-5xl max-h-[95vh] flex flex-col">
            <div className="p-6 border-b border-[#27272a] flex justify-between items-center shrink-0">
              <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                <Eye className="text-purple-400" /> Felhasználó Elemzés
              </h2>
              <button onClick={() => setIsDetailsModalOpen(false)} className="text-gray-400 hover:text-white transition">
                <X size={24} />
              </button>
            </div>

            <div className="p-6 overflow-y-auto custom-scrollbar flex-1">
              {detailsLoading || !selectedUserDetails ? (
                <div className="flex flex-col items-center justify-center h-64 text-purple-400 animate-pulse">
                  <RefreshCw className="animate-spin mb-4" size={40} />
                  <p>Adatelemzés folyamatban...</p>
                </div>
              ) : (
                <div className="space-y-6">
                  <div className="flex flex-col md:flex-row gap-6 items-start">
                    <div className="bg-[#121212] border border-[#27272a] rounded-2xl p-6 flex flex-col items-center text-center min-w-[250px] w-full md:w-auto">
                      <div className="w-24 h-24 rounded-full bg-[#27272a] border-4 border-[#3f3f46] overflow-hidden flex items-center justify-center mb-4">
                        {selectedUserDetails.profilePicture ? (
                          <img src={getImgSrc(selectedUserDetails.profilePicture)} alt="profile" className="w-full h-full object-cover" />
                        ) : (
                          <span className="text-gray-500 font-bold text-3xl">{selectedUserDetails.userName.charAt(0).toUpperCase()}</span>
                        )}
                      </div>
                      <h3 className="text-2xl font-bold text-white">{selectedUserDetails.userName}</h3>
                      <p className="text-gray-500 mb-4">{selectedUserDetails.email}</p>
                      <div className="w-full grid grid-cols-2 gap-2 text-sm text-gray-400">
                        <div className="bg-[#18181b] p-2 rounded-lg border border-[#27272a]"><span className="text-white font-bold">{selectedUserDetails.height}</span> cm</div>
                        <div className="bg-[#18181b] p-2 rounded-lg border border-[#27272a]"><span className="text-white font-bold">{selectedUserDetails.weight}</span> kg</div>
                      </div>
                      <p className="mt-4 text-xs text-gray-500">ID: #{selectedUserDetails.id}</p>
                    </div>

                    <div className="flex-1 grid grid-cols-1 sm:grid-cols-3 gap-4 w-full">
                      <div className="bg-purple-500/10 border border-purple-500/20 rounded-2xl p-5">
                        <div className="flex items-center gap-3 mb-2 text-purple-400">
                          <Users size={20} /> <span className="font-semibold">Barátok</span>
                        </div>
                        <p className="text-3xl font-extrabold text-white">{selectedUserDetails.friendsCount}</p>
                        {selectedUserDetails.friendsList.length > 0 && (
                          <p className="text-xs text-purple-300/70 mt-2 truncate">Pl: {selectedUserDetails.friendsList.slice(0, 3).join(", ")}</p>
                        )}
                      </div>
                      
                      <div className="bg-orange-500/10 border border-orange-500/20 rounded-2xl p-5">
                        <div className="flex items-center gap-3 mb-2 text-orange-400">
                          <Dumbbell size={20} /> <span className="font-semibold">Összes Edzés</span>
                        </div>
                        <p className="text-3xl font-extrabold text-white">{selectedUserDetails.totalWorkouts}</p>
                      </div>

                      <div className="bg-pink-500/10 border border-pink-500/20 rounded-2xl p-5">
                        <div className="flex items-center gap-3 mb-2 text-pink-400">
                          <Utensils size={20} /> <span className="font-semibold">Összes Étkezés</span>
                        </div>
                        <p className="text-3xl font-extrabold text-white">{selectedUserDetails.totalMeals}</p>
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="bg-[#121212] border border-[#27272a] rounded-2xl p-6">
                      <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
                        <Dumbbell className="text-orange-400" size={18} /> Legutóbbi Edzések
                      </h3>
                      <div className="space-y-3">
                        {selectedUserDetails.recentWorkouts.length === 0 ? (
                          <p className="text-gray-500 text-sm">Nincs még rögzített edzés.</p>
                        ) : (
                          selectedUserDetails.recentWorkouts.map(w => (
                            <div key={w.id} className="bg-[#18181b] border border-[#27272a] p-3 rounded-xl flex justify-between items-center">
                              <div>
                                <p className="font-bold text-white text-sm">{w.customName || w.workoutName}</p>
                                <p className="text-xs text-gray-500">{new Date(w.date).toLocaleString('hu-HU', { dateStyle: 'short', timeStyle: 'short' })}</p>
                              </div>
                              <div className="text-right text-xs">
                                <p className="text-gray-400">⏱ {w.durationMinutes} perc</p>
                                <p className="text-orange-400">🔥 {w.totalBurntCalories} kcal</p>
                              </div>
                            </div>
                          ))
                        )}
                      </div>
                    </div>

                    <div className="bg-[#121212] border border-[#27272a] rounded-2xl p-6">
                      <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
                        <Utensils className="text-pink-400" size={18} /> Legutóbbi Étkezések
                      </h3>
                      <div className="space-y-3">
                        {selectedUserDetails.recentMeals.length === 0 ? (
                          <p className="text-gray-500 text-sm">Nincs még rögzített étkezés.</p>
                        ) : (
                          selectedUserDetails.recentMeals.map(m => (
                            <div key={m.id} className="bg-[#18181b] border border-[#27272a] p-3 rounded-xl flex justify-between items-center">
                              <div>
                                <p className="font-bold text-white text-sm">{m.customName || m.mealName}</p>
                                <p className="text-xs text-gray-500">{new Date(m.eatenAt).toLocaleString('hu-HU', { dateStyle: 'short' })}</p>
                              </div>
                              <div className="text-right text-xs">
                                <p className="text-pink-400 font-bold mb-0.5">🔥 {m.totalCalories.toFixed(0)} kcal</p>
                                <div className="flex gap-2 text-gray-500 text-[10px]">
                                  <span>P: {m.totalProtein.toFixed(0)}g</span>
                                  <span>C: {m.totalCarbs.toFixed(0)}g</span>
                                  <span>F: {m.totalFat.toFixed(0)}g</span>
                                </div>
                              </div>
                            </div>
                          ))
                        )}
                      </div>
                    </div>
                  </div>

                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {isEditModalOpen && editingUser && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="bg-[#18181b] border border-[#27272a] rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto custom-scrollbar">
            <div className="sticky top-0 bg-[#18181b] border-b border-[#27272a] p-6 flex justify-between items-center z-10">
              <h2 className="text-xl font-bold text-white">Felhasználó szerkesztése: {editingUser.userName}</h2>
              <button onClick={() => setIsEditModalOpen(false)} className="text-gray-400 hover:text-white transition">
                <X size={24} />
              </button>
            </div>
            <div className="p-6">
              <div className="mb-8 flex items-center gap-6 p-4 bg-[#121212] rounded-xl border border-[#27272a]">
                <div className="w-20 h-20 rounded-full bg-[#27272a] border border-[#3f3f46] overflow-hidden flex items-center justify-center shrink-0">
                  {editingUser.profilePicture ? (
                    <img src={getImgSrc(editingUser.profilePicture)} alt="profile" className="w-full h-full object-cover" />
                  ) : (
                    <span className="text-gray-500 font-bold text-2xl">{editingUser.userName.charAt(0).toUpperCase()}</span>
                  )}
                </div>
                <div>
                  <h3 className="text-white font-semibold mb-2">Profilkép</h3>
                  {editingUser.profilePicture ? (
                    <button 
                      onClick={handleRemoveProfilePicture}
                      className="px-3 py-1.5 bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white rounded-lg text-sm transition flex items-center gap-2"
                    >
                      <ImageOff size={16} /> Nem odaillő kép törlése
                    </button>
                  ) : (
                    <p className="text-gray-500 text-sm">A felhasználónak nincs beállítva profilképe.</p>
                  )}
                </div>
              </div>

              <form onSubmit={handleUpdateSubmit} className="space-y-5">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Felhasználónév</label>
                    <input type="text" required className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-[#40ff32] outline-none" value={editingUser.userName} onChange={e => setEditingUser({...editingUser, userName: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Email</label>
                    <input type="email" required className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-[#40ff32] outline-none" value={editingUser.email} onChange={e => setEditingUser({...editingUser, email: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Magasság (cm)</label>
                    <input type="number" required className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-[#40ff32] outline-none" value={editingUser.height} onChange={e => setEditingUser({...editingUser, height: parseInt(e.target.value) || 0})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Súly (kg)</label>
                    <input type="number" required className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-[#40ff32] outline-none" value={editingUser.weight} onChange={e => setEditingUser({...editingUser, weight: parseInt(e.target.value) || 0})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Nem</label>
                    <select className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-[#40ff32] outline-none" value={editingUser.gender} onChange={e => setEditingUser({...editingUser, gender: e.target.value})}>
                      <option value="Férfi">Férfi</option>
                      <option value="Nő">Nő</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Születési idő</label>
                    <input type="date" required className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-[#40ff32] outline-none [color-scheme:dark]" value={editingUser.birth ? editingUser.birth.split('T')[0] : ""} onChange={e => setEditingUser({...editingUser, birth: new Date(e.target.value).toISOString()})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Cél</label>
                    <select className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-[#40ff32] outline-none" value={editingUser.goal} onChange={e => setEditingUser({...editingUser, goal: e.target.value})}>
                      <option value="Tömegelés">Tömegelés</option>
                      <option value="Szintentartás">Szintentartás</option>
                      <option value="Fogyás">Fogyás</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Aktivitás</label>
                    <select className="w-full bg-[#121212] border border-[#27272a] text-white px-4 py-2.5 rounded-xl focus:border-[#40ff32] outline-none" value={editingUser.activity} onChange={e => setEditingUser({...editingUser, activity: e.target.value})}>
                      <option value="Enyhén_aktív">Enyhén aktív</option>
                      <option value="Közepesen_aktív">Közepesen aktív</option>
                      <option value="Nagyon_aktív">Nagyon aktív</option>
                      <option value="Extrém_aktív">Extrém aktív</option>
                    </select>
                  </div>
                </div>
                <div className="pt-6 flex justify-end gap-3">
                  <button type="button" onClick={() => setIsEditModalOpen(false)} className="px-5 py-2.5 bg-[#27272a] hover:bg-[#3f3f46] text-white rounded-xl transition">Mégse</button>
                  <button type="submit" className="px-5 py-2.5 bg-[#40ff32] hover:bg-[#3ce62e] text-black font-bold rounded-xl transition">Változások mentése</button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UsersPage;