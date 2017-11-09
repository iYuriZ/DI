<!doctype html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>Home</title>
    <link rel="stylesheet" href="CSS/Style.css">
    <link rel="stylesheet" href="/static/css/bootstrap.css">
</head>

<body>

<?php
    require 'app/database.php';

?>

<div class="row main-container">
    <div class="col-md-4"></div>

    <main class="col-md-4">
        <h1>Balies</h1>

        <?php foreach ($content['categories'] as $category) : ?>
            <a href="/category.php?id=<?php echo $category['rubrieknummer'] ?>" class="list-group-item"><?php echo $category['rubrieknaam'] ?></a>
        <?php endforeach; ?>
    </main>

    <div class="col-md-4"></div>
</div>

</body>

</html>
