using System.Text.Json;
using System.Web;
using Zest.Api.DTOs;

public interface IMealService
{
    Task<List<MealDto>> GetMealsFromApiAsync(string query, int page = 1, int size = 10);
}

public class MealService : IMealService
{
    private readonly HttpClient _http;

    public MealService(HttpClient http)
    {
        _http = http;
    }

    public async Task<List<MealDto>> GetMealsFromApiAsync(string query, int page = 1, int size = 10)
    {
        _http.DefaultRequestHeaders.Remove("Cookie");
        _http.DefaultRequestHeaders.Add("Cookie", "myPHP83SESSID=bQa99fWhh5WMDMP8SJIwEZg24r;");

        var uriBuilder = new UriBuilder("https://kaloriabazis.hu/getfood.php");
        var queries = HttpUtility.ParseQueryString(uriBuilder.Query);
        queries["q"] = query;
        queries["p"] = page.ToString();
        queries["s"] = size.ToString();
        queries["expropsearch_id"] = "0";
        queries["expropsearch_inc"] = "0";
        queries["all_public_food"] = "0";
        uriBuilder.Query = queries.ToString();

        var response = await _http.GetAsync(uriBuilder.ToString());
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync();

        var mealResponse = JsonSerializer.Deserialize<MealSearchResponse>(json, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        return mealResponse?.Results2 ?? new List<MealDto>();
    }
}