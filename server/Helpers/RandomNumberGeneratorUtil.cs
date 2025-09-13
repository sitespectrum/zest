using System.Security.Cryptography;

namespace Zest.Api.Helpers
{
    public static class RandomNumberGeneratorUtil
    {
        public static int GenerateRandomNumber(int min, int max)
        {
            using (var rng = RandomNumberGenerator.Create())
            {
                byte[] bytes = new byte[4];
                rng.GetBytes(bytes);
                int value = BitConverter.ToInt32(bytes, 0);
                return new Random(value).Next(min, max);
            }
        }
    }
}
