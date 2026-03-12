import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { loginAdmin } from "../api/api";

const Login = () => {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const data = await loginAdmin(username, password);
      localStorage.setItem("admin_token", data.token);
      localStorage.setItem("admin_name", data.username);
      navigate("/users");
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#0a0a0a] flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-[#121212] border border-[#27272a] rounded-2xl shadow-2xl p-8">
        <div className="flex justify-center mb-6">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-[#27272a] flex items-center justify-center overflow-hidden p-2">
              <img src="/Zest_logo.png" alt="Zest" className="w-full h-full object-contain" />
            </div>
            <span className="text-3xl font-extrabold tracking-wide text-white">
              Zest<span className="text-[#40ff32]">.</span>
            </span>
          </div>
        </div>

        <h2 className="text-xl font-bold text-center text-white mb-6">Admin Bejelentkezés</h2>

        {error && (
          <div className="bg-red-500/10 border border-red-500/20 text-red-500 text-sm p-3 rounded-lg mb-6 text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-5">
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">Felhasználónév</label>
            <input
              type="text"
              required
              className="w-full bg-[#18181b] border border-[#27272a] text-white px-4 py-3 rounded-xl focus:outline-none focus:border-[#40ff32] transition"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">Jelszó</label>
            <input
              type="password"
              required
              className="w-full bg-[#18181b] border border-[#27272a] text-white px-4 py-3 rounded-xl focus:outline-none focus:border-[#40ff32] transition"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-[#40ff32] hover:bg-[#3ce62e] text-black font-bold py-3 rounded-xl transition mt-4 disabled:opacity-50"
          >
            {loading ? "Bejelentkezés..." : "Belépés"}
          </button>
        </form>
      </div>
    </div>
  );
};

export default Login;