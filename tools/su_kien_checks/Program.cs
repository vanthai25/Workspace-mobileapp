using System.Reflection;
using System.Security.Claims;
using HV.DTO;
using HV_api.Controllers.V2;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;

var services = new ServiceCollection().AddLogging().AddAuthorization().BuildServiceProvider();
var policyProvider = services.GetRequiredService<IAuthorizationPolicyProvider>();
var authorization = services.GetRequiredService<IAuthorizationService>();
var controllerType = typeof(SuKienV2Controller);
var checks = 0;
void Check(bool condition, string message)
{
    if (!condition) throw new Exception(message);
    Console.WriteLine($"PASS: {message}");
    checks++;
}
ClaimsPrincipal User(string? role) => role == null
    ? new ClaimsPrincipal(new ClaimsIdentity())
    : new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim(ClaimTypes.Role, role) }, "test"));

foreach (var action in new[] { "Create", "Update", "Delete", "UploadBanner", "UpdateBanner", "DeleteBanner" })
{
    var metadata = controllerType.GetCustomAttributes<AuthorizeAttribute>()
        .Concat(controllerType.GetMethod(action)!.GetCustomAttributes<AuthorizeAttribute>());
    var policy = (await AuthorizationPolicy.CombineAsync(policyProvider, metadata))!;
    foreach (var role in new string?[] { null, "48", "52" })
    {
        var result = await authorization.AuthorizeAsync(User(role), null, policy);
        Check(result.Succeeded == (role == "52"), $"{action}: role {role ?? "anonymous"}");
    }
}
var currentMetadata = controllerType.GetCustomAttributes<AuthorizeAttribute>()
    .Concat(controllerType.GetMethod("GetCurrent")!.GetCustomAttributes<AuthorizeAttribute>());
var currentPolicy = (await AuthorizationPolicy.CombineAsync(policyProvider, currentMetadata))!;
Check((await authorization.AuthorizeAsync(User("48"), null, currentPolicy)).Succeeded,
    "Ordinary authenticated users can load current events");
Check(!(await authorization.AuthorizeAsync(User(null), null, currentPolicy)).Succeeded,
    "Anonymous users cannot load current events");

foreach (var role in new[] { "48", "52" })
{
    var service = DispatchProxy.Create<ISuKienV2Service, EventServiceSpy>();
    var controller = new SuKienV2Controller(service)
    {
        ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext { User = User(role) } }
    };
    await controller.GetBannerImage(1);
    Check(((EventServiceSpy)(object)service).CanPreview == (role == "52"),
        $"Image preview bypass requires role 52 (caller {role})");
}
Console.WriteLine($"Passed {checks} checks. No database connection or writes.");

public class EventServiceSpy : DispatchProxy
{
    public bool CanPreview { get; private set; }
    protected override object? Invoke(MethodInfo? method, object?[]? args)
    {
        if (method?.Name != "GetBannerFileAsync") throw new NotSupportedException();
        CanPreview = (bool)args![1]!;
        return Task.FromResult(ApiResponse<SuKienBannerFileV2DTO>.NotFound("Test image not found"));
    }
}
