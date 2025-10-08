public class MealDto
{
    public string? Id { get; set; }
    public string? FoodId { get; set; }
    public string? Name { get; set; }
    public string? Piece { get; set; }
    public string? Cal { get; set; }
    public string? Protein { get; set; }
    public string? Carbo { get; set; }
    public string? Fat { get; set; }
}

public class MealSearchResponse
{
    public int Total2 { get; set; }
    public List<MealDto> Results2 { get; set; }
}

